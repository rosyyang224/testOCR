import Foundation
import FoundationModels

@MainActor
class QueryLanguageSession {
    private var session: LanguageModelSession?
    private var isFirstInteraction = true
    
    // Session management
    private var conversationHistory: [ConversationTurn] = []
    private var sessionAttempts = 0
    private let maxSessionAttempts = 3
    private let maxHistoryLength = 10
    
    // Context tracking
    private var totalTokensUsed: Int = 0
    private var estimatedContextSize: Int = 0
    
    struct ConversationTurn {
        let query: String
        let response: String
        let timestamp: Date
        let tokenEstimate: Int
    }
    
    enum SessionError: Error {
        case contextLimitExceeded
        case sessionCreationFailed
        case maxAttemptsReached
        case invalidResponse
        
        var localizedDescription: String {
            switch self {
            case .contextLimitExceeded:
                return "Context limit exceeded - creating new session"
            case .sessionCreationFailed:
                return "Failed to create new session"
            case .maxAttemptsReached:
                return "Maximum session attempts reached"
            case .invalidResponse:
                return "Invalid response from language model"
            }
        }
    }

    init() {
        initializeSession()
    }
    
    // MARK: - Session Management
    
    private func initializeSession() {
        sessionAttempts += 1
        
        guard sessionAttempts <= maxSessionAttempts else {
            conversationHistory.removeAll()
            sessionAttempts = 1
            return
        }
        
        let tools: [any Tool] = [
            getHoldingsTool(isSessionStart: true)
        ]
        
        let instructions = buildSessionInstructions()
        
        session = LanguageModelSession(
            tools: tools,
            instructions: instructions
        )
        
        
        estimatedContextSize = estimateTokenCount(instructions)
        
        if sessionAttempts > 1 {
            print("Session recreated with conversation continuity")
        }
    }
    
    private func buildSessionInstructions() -> String {
        // Get context using our clean architecture
        let context = ContextManager.shared.getOptimizedContext()
        
        var instructions = """
        You are a portfolio data assistant. CRITICAL: You MUST call the getHoldings tool for ALL holdings questions.

        MANDATORY TOOL USAGE RULES:
        1. ANY question about holdings, stocks, bonds, positions, or portfolio → IMMEDIATELY call getHoldings
        2. NEVER provide portfolio information without calling the tool first
        3. NEVER say "no holdings found" without calling the tool
        4. NEVER make up portfolio data - only use tool results
        5. When you see "Use getHoldings", "Call getHoldings", "Execute getHoldings" → call the tool immediately

        TOOL CALLING IS MANDATORY FOR:
        - "Do I own [stock]?" → call getHoldings immediately
        - "Show me [anything]" → call getHoldings immediately  
        - "What's [portfolio question]?" → call getHoldings immediately
        - ANY portfolio-related query → call getHoldings immediately

        You are NOT providing financial advice. You are ONLY displaying existing data.

        \(context.toolInstructions)

        CRITICAL EXAMPLES - ALWAYS CALL TOOL:
        1. "Do I have Apple?" → IMMEDIATELY call: getHoldings(filters: [SmartFilter(field: "symbol", condition: "AAPL", filterType: .exact)])
        2. "Show positions with positive performance" → IMMEDIATELY call: getHoldings(filters: [SmartFilter(field: "marketplpercentinsccy", condition: "0", filterType: .greaterThan)])
        3. "Show me stocks" → IMMEDIATELY call: getHoldings(filters: [SmartFilter(field: "assetclass", condition: "Equity", filterType: .exact)])

        REMEMBER: ALWAYS call getHoldings first, then format the results for the user.
        """
        
        return instructions
    }
    
    // MARK: - Query Processing
    
    func send(_ query: String) async throws -> String {
        var lastError: Error?
        
        // Attempt with error recovery
        for attempt in 1...maxSessionAttempts {
            do {
                let response = try await attemptSendQuery(query)
                
                let tokenEstimate = estimateTokenCount(query + response)
                let turn = ConversationTurn(
                    query: query,
                    response: response,
                    timestamp: Date(),
                    tokenEstimate: tokenEstimate
                )
                
                conversationHistory.append(turn)
                totalTokensUsed += tokenEstimate
                
                // Maintain conversation history
                trimConversationHistory()
                checkContextHealth()
                
                return response
                
            } catch {
                lastError = error
                
                if isContextLimitError(error) {
                    try await recreateSessionWithContinuity()
                } else if attempt < maxSessionAttempts {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                }
            }
        }
        
        throw lastError ?? SessionError.maxAttemptsReached
    }
    
    private func attemptSendQuery(_ query: String) async throws -> String {
        guard let session else {
            throw SessionError.sessionCreationFailed
        }

        if isFirstInteraction {
            isFirstInteraction = false
        }
        
        print("session started")
        let result = try await session.respond(to: query)
        
        guard !result.content.isEmpty else {
            throw SessionError.invalidResponse
        }
        
        return result.content
    }
    
    // MARK: - Context Management
    
    private func recreateSessionWithContinuity() async throws {
        session = nil
        isFirstInteraction = true
        initializeSession()
        
        guard session != nil else {
            throw SessionError.sessionCreationFailed
        }
    }
    
    private func checkContextHealth() {
        let currentEstimate = estimatedContextSize + totalTokensUsed
        let warningThreshold = 8000
        let criticalThreshold = 12000
        
        if currentEstimate > criticalThreshold {
            Task {
                try await recreateSessionWithContinuity()
            }
        } else if currentEstimate > warningThreshold {
            print("⚠️ Context approaching limit (\(currentEstimate) tokens)")
        }
    }
    
    private func trimConversationHistory() {
        if conversationHistory.count > maxHistoryLength {
            let keepEarly = 2
            let keepRecent = maxHistoryLength - keepEarly
            
            let earlyTurns = Array(conversationHistory.prefix(keepEarly))
            let recentTurns = Array(conversationHistory.suffix(keepRecent))
            
            conversationHistory = earlyTurns + recentTurns
        }
    }
    
    private func generateConversationSummary() -> String {
        let recentHistory = Array(conversationHistory.suffix(5))
        
        var summary = "RECENT CONVERSATION:\n"
        
        for (index, turn) in recentHistory.enumerated() {
            let timeAgo = formatTimeAgo(turn.timestamp)
            summary += "\(index + 1). [\(timeAgo)] User: \"\(turn.query)\"\n"
            
            let responseSummary = turn.response.count > 200 ?
                String(turn.response.prefix(150)) + "..." :
                turn.response
            summary += "   Assistant: \(responseSummary)\n\n"
        }
        
        // Add user patterns
        let queryPatterns = extractQueryPatterns()
        if !queryPatterns.isEmpty {
            summary += "USER INTERESTS: \(queryPatterns.joined(separator: ", "))\n"
        }
        
        return summary
    }
    
    private func extractQueryPatterns() -> [String] {
        var patterns: [String] = []
        let queries = conversationHistory.map { $0.query.lowercased() }
        
        if queries.contains(where: { $0.contains("apple") || $0.contains("aapl") }) {
            patterns.append("Apple stock")
        }
        if queries.contains(where: { $0.contains("performance") || $0.contains("top") || $0.contains("best") }) {
            patterns.append("performance analysis")
        }
        if queries.contains(where: { $0.contains("us") || $0.contains("american") }) {
            patterns.append("US markets")
        }
        
        return patterns
    }
    
    // MARK: - Utilities
    
    private func isContextLimitError(_ error: Error) -> Bool {
        let errorString = error.localizedDescription.lowercased()
        return errorString.contains("context") &&
               (errorString.contains("limit") || errorString.contains("length") || errorString.contains("token"))
    }
    
    private func formatTimeAgo(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 60 {
            return "\(Int(interval))s ago"
        } else if interval < 3600 {
            return "\(Int(interval/60))m ago"
        } else {
            return "\(Int(interval/3600))h ago"
        }
    }
    
    private func estimateTokenCount(_ text: String) -> Int {
        return text.count / 4  // Rough estimation: ~4 characters per token
    }
    
    // MARK: - Context
    
    /// Refresh context when data changes
    func refreshContext() {
        ContextManager.shared.invalidateCache()
        sessionAttempts = 0
        initializeSession()
        isFirstInteraction = true
    }
    
    /// Get current context statistics for debugging
    func getContextStats() -> String {
        let context = ContextManager.shared.getOptimizedContext()
        let currentEstimate = estimatedContextSize + totalTokensUsed
        
        return """
        Portfolio Context:
        - Schema: \(context.compactSchema.count) chars
        - Portfolio: \(context.portfolioSummary.count) chars
        - Total context: \(context.fullSessionContext.count) chars
        
        Session Stats:
        - Attempts: \(sessionAttempts)/\(maxSessionAttempts)
        - Conversation turns: \(conversationHistory.count)
        - Tokens used: \(totalTokensUsed)
        - Context estimate: \(currentEstimate)
        - First interaction: \(isFirstInteraction)
        """
    }
    
    /// Clear conversation history (fresh start)
    func clearHistory() {
        conversationHistory.removeAll()
        totalTokensUsed = 0
        sessionAttempts = 0
    }
    
    /// Get conversation history for debugging
    func getConversationHistory() -> [ConversationTurn] {
        return conversationHistory
    }
    
    /// Force session recreation (for testing)
    func forceSessionRecreation() async throws {
        try await recreateSessionWithContinuity()
    }
}
