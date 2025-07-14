import Foundation
import FoundationModels

@MainActor
class QueryLanguageSession {
    private var session: LanguageModelSession?
    private var isFirstInteraction = true
    
    // Error handling and session continuity
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
                return "Context limit exceeded - creating new session with conversation summary"
            case .sessionCreationFailed:
                return "Failed to create new session"
            case .maxAttemptsReached:
                return "Maximum session recreation attempts reached"
            case .invalidResponse:
                return "Invalid response from language model"
            }
        }
    }

    init() {
        print("🚀 [QueryLanguageSession] Initializing new session...")
        initializeSession()
    }
    
    private func initializeSession() {
        let startTime = Date()
        sessionAttempts += 1
        
        print("🔄 [QueryLanguageSession] Starting session initialization (attempt \(sessionAttempts)/\(maxSessionAttempts))")
        
        guard sessionAttempts <= maxSessionAttempts else {
            print("❌ [QueryLanguageSession] Max session attempts reached, resetting conversation")
            conversationHistory.removeAll()
            sessionAttempts = 1
            return
        }
        
        // Step 1: Load mock JSON data (keeping your existing schema generation)
        let mockJSON = mockData
        print("✅ [QueryLanguageSession] Mock data loaded: \(mockJSON.count) characters")

        // Step 2: Try to generate dynamic schema (keeping your existing logic)
        let schema: GenerationSchema
        do {
            let schemaStartTime = Date()
            schema = try SchemaGenerator.generateSchema(from: mockJSON)
            let schemaTime = Date().timeIntervalSince(schemaStartTime)
            print("✅ [QueryLanguageSession] Schema generated successfully in \(String(format: "%.3f", schemaTime))s")
        } catch {
            print("⚠️ [QueryLanguageSession] Schema generation failed: \(error)")
            do {
                schema = try GenerationSchema(
                    root: DynamicGenerationSchema(name: "MockData", properties: []),
                    dependencies: []
                )
                print("✅ [QueryLanguageSession] Fallback schema created")
            } catch {
                print("❌ [QueryLanguageSession] Failed to create fallback schema: \(error)")
                fatalError("Unable to create any schema - check your GenerationSchema API")
            }
        }

        // Step 3: Create tools with session-aware context
        print("🛠️ [QueryLanguageSession] Creating tools with session context...")
        let tools: [any Tool] = [
            SmartHoldingsTool(isSessionStart: true)  // Enable full context at session start
        ]
        print("✅ [QueryLanguageSession] Created \(tools.count) tools")

        // Step 4: Build instructions with conversation continuity
        let instructions = buildSessionInstructions()
        
        // Step 5: Initialize session with enhanced instructions
        session = LanguageModelSession(
            tools: tools,
            instructions: instructions
        )
        
        // Estimate initial context size
        estimatedContextSize = estimateTokenCount(instructions)
        
        let initTime = Date().timeIntervalSince(startTime)
        print("📊 [QueryLanguageSession] Initialization stats:")
        print("   - Attempt: \(sessionAttempts)/\(maxSessionAttempts)")
        print("   - Time: \(String(format: "%.3f", initTime))s")
        print("   - Estimated context: \(estimatedContextSize) tokens")
        print("   - Instructions length: \(instructions.count) chars")
        print("   - Conversation history: \(conversationHistory.count) turns")
        
        if sessionAttempts > 1 {
            print("🔄 [QueryLanguageSession] Session recreated with conversation continuity")
        }
    }
    
    private func buildSessionInstructions() -> String {
        print("📋 [QueryLanguageSession] Building session instructions...")
        
        var instructions = """
        You are a helpful financial assistant. ALWAYS use the getHoldings tool to answer questions about portfolio holdings.

        CRITICAL: For ANY question about holdings, positions, stocks, bonds, or investments, you MUST call the getHoldings tool.

        RESPONSE STYLE:
        - Be conversational and direct
        - ALWAYS call getHoldings tool for portfolio questions
        - Show actual holdings data, not explanations
        - If user asks "Do I have Apple?" → Use getHoldings tool with symbol="AAPL" filter
        - If user asks "What's performing well?" → Use getHoldings tool with performance sorting
        
        MANDATORY TOOL USAGE:
        - User asks about any company → Call getHoldings with appropriate symbol filter
        - User asks about performance → Call getHoldings with performance sorting
        - User asks about asset types → Call getHoldings with assetclass filter
        - User asks about regions → Call getHoldings with countryregion filter
        - User asks about position sizes → Call getHoldings with totalmarketvalue sorting
        
        NEVER explain what you would do - ALWAYS do it by calling the tool.
        """
        
        // Add conversation continuity if this is a session recreation
        if sessionAttempts > 1 && !conversationHistory.isEmpty {
            print("📚 [QueryLanguageSession] Adding conversation continuity...")
            let conversationSummary = generateConversationSummary()
            instructions += """
            
            CONVERSATION CONTINUITY:
            Previous context: \(conversationSummary)
            Continue naturally, maintaining context from above.
            """
            print("✅ [QueryLanguageSession] Added conversation summary: \(conversationSummary.count) chars")
        }
        
        instructions += """

        TOOL USAGE EXAMPLES:
        
        1. "Do I have Apple?" → IMMEDIATELY call:
        getHoldings(filters: [SmartFilter(field: "symbol", condition: "AAPL", filterType: .exact)])
        
        2. "What's my best performing stock?" → IMMEDIATELY call:
        getHoldings(filters: [SmartFilter(field: "marketplpercentinsccy", condition: "0", filterType: .greaterThan)], sortBy: .performance, limit: 1)
        
        3. "Show me my US positions" → IMMEDIATELY call:
        getHoldings(filters: [SmartFilter(field: "countryregion", condition: "United States", filterType: .exact)])
        
        4. "My bonds?" → IMMEDIATELY call:
        getHoldings(filters: [SmartFilter(field: "assetclass", condition: "Fixed Income", filterType: .exact)])

        COMPANY NAME MAPPINGS (use these in tool calls):
        - Apple → symbol = "AAPL"
        - Tesla → symbol = "TSLA"  
        - Alibaba → symbol = "9988.HK"

        FIELD MAPPINGS (use exact field names):
        - Performance: marketplpercentinsccy
        - Position size: totalmarketvalue
        - Asset type: assetclass
        - Geography: countryregion
        - Stock symbol: symbol

        REMEMBER: ALWAYS call the getHoldings tool for portfolio questions. Never just explain - always execute!
        """
        
        print("✅ [QueryLanguageSession] Instructions built: \(instructions.count) total chars")
        return instructions
    }
    
    private func generateConversationSummary() -> String {
        print("📝 [QueryLanguageSession] Generating conversation summary...")
        
        // Take the most recent conversations (limit to prevent bloat)
        let recentHistory = Array(conversationHistory.suffix(5))
        print("   📚 [QueryLanguageSession] Using \(recentHistory.count) recent conversation turns")
        
        var summary = "RECENT CONVERSATION SUMMARY:\n"
        
        for (index, turn) in recentHistory.enumerated() {
            let timeAgo = formatTimeAgo(turn.timestamp)
            summary += "\(index + 1). [\(timeAgo)] User: \"\(turn.query)\"\n"
            
            // Summarize long responses
            let responseSummary = turn.response.count > 200 ?
                String(turn.response.prefix(150)) + "..." :
                turn.response
            summary += "   Assistant: \(responseSummary)\n\n"
        }
        
        // Add context about user preferences/patterns
        let queryPatterns = extractQueryPatterns()
        if !queryPatterns.isEmpty {
            summary += "USER QUERY PATTERNS: \(queryPatterns.joined(separator: ", "))\n"
            print("   🎯 [QueryLanguageSession] Detected query patterns: \(queryPatterns)")
        }
        
        print("✅ [QueryLanguageSession] Conversation summary generated: \(summary.count) chars")
        return summary
    }
    
    private func extractQueryPatterns() -> [String] {
        var patterns: [String] = []
        let queries = conversationHistory.map { $0.query.lowercased() }
        
        if queries.contains(where: { $0.contains("apple") || $0.contains("aapl") }) {
            patterns.append("interested in Apple stock")
        }
        if queries.contains(where: { $0.contains("performance") || $0.contains("top") || $0.contains("best") }) {
            patterns.append("focuses on performance analysis")
        }
        if queries.contains(where: { $0.contains("us") || $0.contains("american") }) {
            patterns.append("interested in US markets")
        }
        
        return patterns
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

    func send(_ query: String) async throws -> String {
        let startTime = Date()
        print("💬 [QueryLanguageSession] Received user query: '\(query)'")
        print("📊 [QueryLanguageSession] Query stats: \(query.count) chars, estimated \(estimateTokenCount(query)) tokens")
        
        var lastError: Error?
        
        // Attempt to send query with error recovery
        for attempt in 1...maxSessionAttempts {
            print("🔄 [QueryLanguageSession] Processing attempt \(attempt)/\(maxSessionAttempts)")
            
            do {
                let response = try await attemptSendQuery(query)
                let processingTime = Date().timeIntervalSince(startTime)
                
                print("✅ [QueryLanguageSession] Query processed successfully in \(String(format: "%.3f", processingTime))s")
                print("📤 [QueryLanguageSession] Response: \(response.count) chars, estimated \(estimateTokenCount(response)) tokens")
                
                // Success! Record the conversation turn
                let tokenEstimate = estimateTokenCount(query + response)
                let turn = ConversationTurn(
                    query: query,
                    response: response,
                    timestamp: Date(),
                    tokenEstimate: tokenEstimate
                )
                
                conversationHistory.append(turn)
                totalTokensUsed += tokenEstimate
                
                print("📝 [QueryLanguageSession] Conversation turn recorded:")
                print("   - Turn #\(conversationHistory.count)")
                print("   - Token estimate: \(tokenEstimate)")
                print("   - Total tokens used: \(totalTokensUsed)")
                
                // Trim history if it gets too long
                trimConversationHistory()
                
                // Check if we're approaching context limits
                checkContextHealth()
                
                print("--- RESPONSE START ---")
                print(response)
                print("--- RESPONSE END ---")
                
                return response
                
            } catch {
                lastError = error
                print("❌ [QueryLanguageSession] Attempt \(attempt) failed: \(error.localizedDescription)")
                
                if isContextLimitError(error) {
                    print("🚨 [QueryLanguageSession] Context limit detected, recreating session...")
                    try await recreateSessionWithContinuity()
                } else if attempt < maxSessionAttempts {
                    print("⏳ [QueryLanguageSession] Retrying in 1 second...")
                    try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                }
            }
        }
        
        print("💥 [QueryLanguageSession] All attempts failed, throwing final error")
        throw lastError ?? SessionError.maxAttemptsReached
    }
    
    private func attemptSendQuery(_ query: String) async throws -> String {
        print("🎯 [QueryLanguageSession] Attempting to send query to LanguageModelSession...")
        
        guard let session else {
            print("❌ [QueryLanguageSession] No active session available")
            throw SessionError.sessionCreationFailed
        }

        // Track first interaction for context efficiency
        if isFirstInteraction {
            isFirstInteraction = false
            print("🎪 [QueryLanguageSession] This is the first interaction - full context will be used")
            print("⚡ [QueryLanguageSession] Subsequent queries will use learned context for efficiency")
        } else {
            print("🔄 [QueryLanguageSession] Using learned context from previous interactions")
        }

        print("🧠 [QueryLanguageSession] Sending query to LLM...")
        print("--- LLM INPUT START ---")
        print("Query: \(query)")
        print("--- LLM INPUT END ---")
        
        let llmStartTime = Date()
        let result = try await session.respond(to: query)
        let llmTime = Date().timeIntervalSince(llmStartTime)
        
        print("🧠 [QueryLanguageSession] LLM response received in \(String(format: "%.3f", llmTime))s")
        print("--- LLM OUTPUT START ---")
        print(result.content)
        print("--- LLM OUTPUT END ---")
        
        guard !result.content.isEmpty else {
            print("❌ [QueryLanguageSession] LLM returned empty response")
            throw SessionError.invalidResponse
        }
        
        print("✅ [QueryLanguageSession] LLM response validated successfully")
        return result.content
    }
    
    private func isContextLimitError(_ error: Error) -> Bool {
        let errorString = error.localizedDescription.lowercased()
        let isContextError = errorString.contains("context") &&
               (errorString.contains("limit") || errorString.contains("length") || errorString.contains("token"))
        
        print("🔍 [QueryLanguageSession] Checking if error is context-related:")
        print("   - Error: \(errorString)")
        print("   - Is context error: \(isContextError)")
        
        return isContextError
    }
    
    private func recreateSessionWithContinuity() async throws {
        print("🔄 [QueryLanguageSession] Starting session recreation with continuity...")
        let recreationStartTime = Date()
        
        // Reset session state but preserve history
        session = nil
        isFirstInteraction = true
        
        print("💾 [QueryLanguageSession] Preserving conversation history: \(conversationHistory.count) turns")
        
        // Initialize new session with conversation summary
        initializeSession()
        
        guard session != nil else {
            print("❌ [QueryLanguageSession] Failed to recreate session")
            throw SessionError.sessionCreationFailed
        }
        
        let recreationTime = Date().timeIntervalSince(recreationStartTime)
        print("✅ [QueryLanguageSession] Session recreated successfully in \(String(format: "%.3f", recreationTime))s")
    }
    
    private func checkContextHealth() {
        let currentEstimate = estimatedContextSize + totalTokensUsed
        let warningThreshold = 8000  // Adjust based on your model's limits
        let criticalThreshold = 12000
        
        print("🏥 [QueryLanguageSession] Context health check:")
        print("   - Initial context: \(estimatedContextSize) tokens")
        print("   - Conversation tokens: \(totalTokensUsed) tokens")
        print("   - Total estimate: \(currentEstimate) tokens")
        print("   - Warning threshold: \(warningThreshold) tokens")
        print("   - Critical threshold: \(criticalThreshold) tokens")
        
        if currentEstimate > criticalThreshold {
            print("🚨 [QueryLanguageSession] CRITICAL: Context approaching limit (\(currentEstimate) tokens)")
            print("🔄 [QueryLanguageSession] Auto-recreating session to prevent overflow...")
            Task {
                try await recreateSessionWithContinuity()
            }
        } else if currentEstimate > warningThreshold {
            print("⚠️ [QueryLanguageSession] WARNING: Context approaching limit (\(currentEstimate) tokens)")
        } else {
            print("✅ [QueryLanguageSession] Context health: Good (\(currentEstimate) tokens)")
        }
    }
    
    private func trimConversationHistory() {
        if conversationHistory.count > maxHistoryLength {
            print("✂️ [QueryLanguageSession] Trimming conversation history (current: \(conversationHistory.count), max: \(maxHistoryLength))")
            
            // Keep the most recent conversations and a few early ones for context
            let keepEarly = 2
            let keepRecent = maxHistoryLength - keepEarly
            
            let earlyTurns = Array(conversationHistory.prefix(keepEarly))
            let recentTurns = Array(conversationHistory.suffix(keepRecent))
            
            conversationHistory = earlyTurns + recentTurns
            print("🧹 [QueryLanguageSession] History trimmed to \(conversationHistory.count) turns (kept \(keepEarly) early + \(keepRecent) recent)")
        } else {
            print("📚 [QueryLanguageSession] Conversation history within limits: \(conversationHistory.count)/\(maxHistoryLength)")
        }
    }
    
    private func estimateTokenCount(_ text: String) -> Int {
        // Rough estimation: ~4 characters per token for English
        let estimate = text.count / 4
        return estimate
    }
    
    /// Call this when your data changes to refresh context
    func refreshContext() {
        print("🔄 [QueryLanguageSession] Manual context refresh requested")
        print("💾 [QueryLanguageSession] Current state before refresh:")
        print("   - Session attempts: \(sessionAttempts)")
        print("   - Conversation turns: \(conversationHistory.count)")
        print("   - Total tokens: \(totalTokensUsed)")
        
        ContextManager.shared.invalidateCache()
        sessionAttempts = 0  // Reset attempt counter
        initializeSession()
        isFirstInteraction = true
        
        print("✅ [QueryLanguageSession] Context refresh completed")
    }
    
    /// Get current context statistics for debugging
    func getContextStats() -> String {
        print("📊 [QueryLanguageSession] Generating context statistics...")
        
        let context = ContextManager.shared.getOptimizedContext()
        let currentEstimate = estimatedContextSize + totalTokensUsed
        
        let stats = """
        \(context.debugInfo)
        Session attempts: \(sessionAttempts)/\(maxSessionAttempts)
        Conversation turns: \(conversationHistory.count)
        Total tokens used: \(totalTokensUsed)
        Current context estimate: \(currentEstimate)
        Is first interaction: \(isFirstInteraction)
        """
        
        print("📋 [QueryLanguageSession] Context stats generated")
        return stats
    }
    
    /// Test the natural language processing with sample queries
    func runNLPTests() async {
        let testQueries = [
            "show me Apple",
            "top performing tech stocks",
            "my US positions over $20000",
            "worst performing stocks",
            "all my bonds"
        ]
        
        print("🧪 [QueryLanguageSession] Starting NLP tests with \(testQueries.count) queries...")
        
        for (index, query) in testQueries.enumerated() {
            print("🔬 [QueryLanguageSession] Test \(index + 1)/\(testQueries.count): '\(query)'")
            
            do {
                let startTime = Date()
                let result = try await send(query)
                let testTime = Date().timeIntervalSince(startTime)
                
                print("✅ [QueryLanguageSession] Test \(index + 1) PASSED in \(String(format: "%.3f", testTime))s")
                print("   Response length: \(result.count) chars")
            } catch {
                print("❌ [QueryLanguageSession] Test \(index + 1) FAILED: \(error)")
            }
            
            // Small delay between tests
            if index < testQueries.count - 1 {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second
            }
        }
        
        print("🏁 [QueryLanguageSession] NLP tests completed")
        print("📊 [QueryLanguageSession] Final test statistics:")
        print(getContextStats())
    }
    
    /// Force a session recreation (useful for testing)
    func forceSessionRecreation() async throws {
        print("🔧 [QueryLanguageSession] Force session recreation requested")
        try await recreateSessionWithContinuity()
    }
    
    /// Get conversation history for debugging
    func getConversationHistory() -> [ConversationTurn] {
        print("📚 [QueryLanguageSession] Conversation history requested: \(conversationHistory.count) turns")
        for (index, turn) in conversationHistory.enumerated() {
            print("   [\(index + 1)] \(formatTimeAgo(turn.timestamp)): '\(turn.query)' → \(turn.response.count) chars")
        }
        return conversationHistory
    }
    
    /// Clear conversation history (fresh start)
    func clearHistory() {
        print("🧹 [QueryLanguageSession] Clearing conversation history...")
        print("   - Removing \(conversationHistory.count) turns")
        print("   - Resetting \(totalTokensUsed) tokens")
        
        conversationHistory.removeAll()
        totalTokensUsed = 0
        sessionAttempts = 0
        
        print("✅ [QueryLanguageSession] History cleared - fresh start ready")
    }
}
