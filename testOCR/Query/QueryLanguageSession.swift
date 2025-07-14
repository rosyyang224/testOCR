import Foundation
import FoundationModels

@MainActor
class QueryLanguageSession {
    private var session: LanguageModelSession?
    private var isFirstInteraction = true

    init() {
        initializeSession()
    }
    
    private func initializeSession() {
        // Step 1: Load mock JSON data (keeping your existing schema generation)
        let mockJSON = mockData

        // Step 2: Try to generate dynamic schema (keeping your existing logic)
        let schema: GenerationSchema
        do {
            schema = try SchemaGenerator.generateSchema(from: mockJSON)
        } catch {
            print("Schema generation failed: \(error)")
            do {
                schema = try GenerationSchema(
                    root: DynamicGenerationSchema(name: "MockData", properties: []),
                    dependencies: []
                )
            } catch {
                print("Failed to create fallback schema: \(error)")
                fatalError("Unable to create any schema - check your GenerationSchema API")
            }
        }

        // Step 3: Create tools with session-aware context
        let tools: [any Tool] = [
            SmartHoldingsTool(isSessionStart: true)  // Enable full context at session start
        ]

        // Step 4: Initialize session with enhanced natural language instructions
        session = LanguageModelSession(
            tools: tools,
            instructions: """
            You are an intelligent portfolio assistant with comprehensive context about the user's holdings.

            CONTEXT STRATEGY:
            - Full schema and portfolio context loaded at session start for optimal token efficiency
            - Use this learned context for all subsequent queries without repeating full details
            - Map natural language to exact field names using established patterns

            NATURAL LANGUAGE PROCESSING CAPABILITIES:
            Use the `getHoldings` tool to handle these query types:

            1. COMPANY NAME RESOLUTION:
               - "Apple" or "apple" → symbol = "AAPL"
               - "Tesla" → symbol = "TSLA"
               - "Alibaba" → symbol = "9988.HK"
               - Use company mappings from session context

            2. PERFORMANCE QUERIES:
               - "top performing", "best performers", "winners" → marketplpercentinsccy > 0, sort descending
               - "worst performing", "underperforming", "losers" → marketplpercentinsccy < 0, sort ascending
               - "gaining stocks" → filter marketplpercentinsccy > 0
               - "declining positions" → filter marketplpercentinsccy < 0

            3. ASSET TYPE QUERIES:
               - "tech stocks", "technology stocks" → assetclass = "Equity" + identify tech companies
               - "stocks", "equities" → assetclass = "Equity"
               - "bonds", "fixed income" → assetclass = "Fixed Income"

            4. GEOGRAPHIC QUERIES:
               - "US stocks", "American stocks" → countryregion = "United States"
               - "Hong Kong stocks", "HK stocks" → countryregion = "Hong Kong"

            5. VALUE-BASED QUERIES:
               - "large positions", "biggest holdings" → sort by totalmarketvalue descending
               - "small positions" → sort by totalmarketvalue ascending
               - "over $20000" → totalmarketvalue > 20000
               - "under $15000" → totalmarketvalue < 15000

            PROCESSING APPROACH:
            1. Analyze the user's natural language query
            2. Identify the intent (company lookup, performance analysis, filtering, etc.)
            3. Convert to appropriate structured filters using exact field names from session context
            4. Add sorting if performance ranking or value ordering is implied
            5. Set reasonable limits if "top 3" or similar phrases are used

            EXAMPLES OF PROPER CONVERSION:
            - "Show me Apple" → filters: [field: "symbol", condition: "AAPL", filterType: .exact]
            - "top performing tech stocks" → filters: [assetclass = "Equity"], sortBy: "marketplpercentinsccy", sortDirection: .descending
            - "my worst US stocks" → filters: [countryregion = "United States", assetclass = "Equity"], sortBy: "marketplpercentinsccy", sortDirection: .ascending
            - "positions over $20000" → filters: [field: "totalmarketvalue", condition: "20000", filterType: .greaterThan]

            Always use exact field names from the schema context. Convert natural language efficiently into structured filters.
            Context is front-loaded for token efficiency - use learned mappings for subsequent interactions.
            """
        )
        
        print("🚀 Portfolio session initialized with dynamic context and NLP capabilities")
    }

    func send(_ query: String) async throws -> String {
        guard let session else {
            throw NSError(domain: "SessionError", code: 0, userInfo: [
                NSLocalizedDescriptionKey: "Language model session was not initialized"
            ])
        }

        // Track first interaction for context efficiency
        if isFirstInteraction {
            isFirstInteraction = false
            print("💬 First query processed with full context - subsequent queries use learned context")
        }

        let result = try await session.respond(to: query)
        return result.content
    }
    
    /// Call this when your data changes to refresh context
    func refreshContext() {
        print("Refreshing context due to data changes")
        ContextManager.shared.invalidateCache()
        initializeSession()
        isFirstInteraction = true
    }
    
    /// Get current context statistics for debugging
    func getContextStats() -> String {
        let context = ContextManager.shared.getOptimizedContext()
        return context.debugInfo
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
        
        print("🧪 Running NLP tests...")
        for query in testQueries {
            do {
                let result = try await send(query)
                print("'\(query)' → Success")
            } catch {
                print("'\(query)' → Failed: \(error)")
            }
        }
    }
}
