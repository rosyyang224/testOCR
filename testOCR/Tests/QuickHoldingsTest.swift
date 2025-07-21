//// Tests/FocusedHoldingsTest.swift
//import Foundation
//import FoundationModels
//
//@MainActor
//class FocusedHoldingsTest {
//    private var querySession: QueryLanguageSession?
//    
//    func runFocusedTests() async {
//        print("Focused getHoldings Tool Tests")
//        print("Testing: Return holdings filtered intelligently based on user intent")
//        print("==================================================================================================\n")
//        
//        setupSession()
//        
//        // Core filtering tests - simple, direct queries
//        await testBasicFiltering()
//        await testPerformanceFiltering()
//        await testAssetTypeFiltering()
//        await testGeographicFiltering()
//        
//        print("==================================================================================================\n")
//        print("Focused tests complete!")
//        
//        if let session = querySession {
//            printSimpleStats(session)
//        }
//    }
//    
//    private func setupSession() {
//        querySession = QueryLanguageSession()
//        print("Session initialized\n")
//    }
//    
//    // MARK: - Basic Filtering Tests
//    
//    func testBasicFiltering() async {
//        print("BASIC FILTERING TESTS")
//        print("==================================================================================================\n")
//        
//        await testQuery("Use getHoldings tool to check: Do I own Apple?", expectedBehavior: "Filter by symbol=AAPL")
//        await testQuery("Call getHoldings to find: Do I have Tesla?", expectedBehavior: "Filter by symbol=TSLA")
//        await testQuery("Execute getHoldings for symbol AAPL", expectedBehavior: "Filter by symbol=AAPL")
//    }
//    
//    func testPerformanceFiltering() async {
//        print("\nPERFORMANCE FILTERING TESTS")
//        print("==================================================================================================\n")
//        
//        await testQuery("Use getHoldings to show positions with positive performance", expectedBehavior: "Filter performance > 0")
//        await testQuery("Call getHoldings for holdings with negative performance", expectedBehavior: "Filter performance < 0")
//        await testQuery("Execute getHoldings to find my best performing holding", expectedBehavior: "Filter performance > 0, sort DESC, limit 1")
//        await testQuery("Use getHoldings to find worst performing position", expectedBehavior: "Filter performance < 0, sort ASC, limit 1")
//    }
//    
//    func testAssetTypeFiltering() async {
//        print("\nASSET TYPE FILTERING TESTS")
//        print("==================================================================================================\n")
//        
//        await testQuery("Call getHoldings to show equity positions", expectedBehavior: "Filter assetclass=Equity")
//        await testQuery("Use getHoldings to find Fixed Income holdings", expectedBehavior: "Filter assetclass=Fixed Income")
//        await testQuery("Execute getHoldings for all stock positions", expectedBehavior: "Filter assetclass=Equity")
//    }
//    
//    func testGeographicFiltering() async {
//        print("\nGEOGRAPHIC FILTERING TESTS")
//        print("==================================================================================================\n")
//        
//        await testQuery("Call getHoldings for United States holdings", expectedBehavior: "Filter countryregion=United States")
//        await testQuery("Use getHoldings to show non-US positions", expectedBehavior: "Filter countryregion≠United States")
//        await testQuery("Execute getHoldings for international holdings", expectedBehavior: "Filter countryregion≠United States")
//    }
//    
//    // MARK: - Test Execution
//    
//    func testQuery(_ query: String, expectedBehavior: String) async {
//        print("\n\"\(query)\"")
//        print("   Expected: \(expectedBehavior)")
//        
//        guard let session = querySession else {
//            print("Session not initialized")
//            return
//        }
//        
//        let startTime = Date()
//        
//        do {
//            let response = try await session.send(query)
//            let responseTime = Date().timeIntervalSince(startTime)
//            
//            if response.isEmpty {
//                print("No response (\(String(format: "%.1f", responseTime))s)")
//            } else {
//                print("Response time: \(String(format: "%.1f", responseTime))s")
//        
//                
//                print(response)
//            }
//            
//        } catch {
//            let responseTime = Date().timeIntervalSince(startTime)
//            print("Error after \(String(format: "%.1f", responseTime))s: \(error.localizedDescription)")
//        }

//    }
//    
//    func printSimpleStats(_ session: QueryLanguageSession) {
//        let history = session.getConversationHistory()
//        print("\nSession Summary:")
//        print("- Total queries: \(history.count)")
//        
//        guard !history.isEmpty && history.count > 1 else {
//            print("- Not enough data for response time analysis")
//            return
//        }
//        
//        // Calculate response times based on conversation history timestamps
//        var responseTimes: [Double] = []
//        
//        for i in 1..<history.count {  // Start from 1, not 0
//            let turn = history[i]
//            let previousTurn = history[i-1]
//            let timeDiff = turn.timestamp.timeIntervalSince(previousTurn.timestamp)
//            if timeDiff > 0 {  // Only add positive time differences
//                responseTimes.append(timeDiff)
//            }
//        }
//        
//        if !responseTimes.isEmpty {
//            let avgTime = responseTimes.reduce(0, +) / Double(responseTimes.count)
//            let timeStrings = responseTimes.map { String(format: "%.1fs", $0) }
//            print("- Response times: \(timeStrings.joined(separator: ", "))")
//            print("- Average response time: \(String(format: "%.1f", avgTime))s")
//        } else {
//            print("- No valid response times calculated")
//        }
//    }
//    
//    // Debug function to see available data
//    func debugAvailableData() async {
//        print("\n🔍 DEBUG: Available Data")
//        print(String(repeating: "=", count: 50))
//        
//        let tool = getHoldingsTool(isSessionStart: true)
//        
//        // Get ALL holdings to see what's available
//        let allHoldings = getHoldingsTool.Arguments(
//            intent: "show all",
//            filters: [],
//            limit: nil
//        )
//        
//        let result = await tool.call(arguments: allHoldings)
//        print("ALL HOLDINGS:")
//        print(extractToolContent(result))
//        
//        // Test losing positions filter directly
//        let losingTest = getHoldingsTool.Arguments(
//            intent: "losing positions",
//            filters: [getHoldingsTool.Arguments.SmartFilter(
//                field: "marketplpercentinsccy",
//                condition: "0",
//                filterType: .lessThan
//            )],
//            limit: nil
//        )
//        
//        let losingResult = await tool.call(arguments: losingTest)
//        print("\nLOSING POSITIONS (performance < 0):")
//        print(extractToolContent(losingResult))
//        
//        // Test bonds filter
//        let bondsTest = getHoldingsTool.Arguments(
//            intent: "show bonds",
//            filters: [getHoldingsTool.Arguments.SmartFilter(
//                field: "assetclass",
//                condition: "Fixed Income",
//                filterType: .exact
//            )],
//            limit: nil
//        )
//        
//        let bondsResult = await tool.call(arguments: bondsTest)
//        print("\nBONDS (assetclass = Fixed Income):")
//        print(extractToolContent(bondsResult))
//    }
//    
//    func extractToolContent(_ toolOutput: ToolOutput) -> String {
//        let description = String(describing: toolOutput)
//        if description.hasPrefix("ToolOutput(content: \"") && description.hasSuffix("\")") {
//            let start = description.index(description.startIndex, offsetBy: 19)
//            let end = description.index(description.endIndex, offsetBy: -2)
//            let content = String(description[start..<end])
//            return content.replacingOccurrences(of: "\\n", with: "\n")
//        }
//        return description
//    }
//}
//
//// Even simpler test for quick validation
//@MainActor
//class QuickValidationTest {
//    
//    func runQuickValidation() async {
//        print("Quick Validation Test")
//        print("Testing core getHoldings functionality")
//        print("==================================================================================================\n")
//        
//        let session = QueryLanguageSession()
//        
//        // Explicit tool-calling tests
//        let coreTests = [
//            ("Execute getHoldings with no filters to show all holdings", "Should return all 4 holdings"),
//            ("Call getHoldings filtered by symbol=AAPL", "Should find Apple"),
//            ("Use getHoldings to find assetclass=Equity positions", "Should filter to stocks")
//        ]
//        
//        for (query, expected) in coreTests {
//            print("\n🔍 \(query)")
//            print("   \(expected)")
//            
//            let startTime = Date()
//            
//            do {
//                let response = try await session.send(query)
//                let responseTime = Date().timeIntervalSince(startTime)
//                
//                print("Response time: \(String(format: "%.1f", responseTime))s")
//                
//                print(response)
//                
//            } catch {
//                let responseTime = Date().timeIntervalSince(startTime)
//                print("Error after \(String(format: "%.1f", responseTime))s: \(error.localizedDescription)")
//            }
//        }
//        
//        print("\nQuick validation complete")
//    }
//}
