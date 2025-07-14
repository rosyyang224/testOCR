// Tests/FocusedHoldingsTest.swift
import Foundation
import FoundationModels

@MainActor
class FocusedHoldingsTest {
    private var querySession: QueryLanguageSession?
    
    func runFocusedTests() async {
        print("Focused getHoldings Tool Tests")
        print("Testing: Return holdings filtered intelligently based on user intent")
        print("==================================================================================================\n")
        
        setupSession()
        
        // Core filtering tests - simple, direct queries
        await testBasicFiltering()
        await testPerformanceFiltering()
        await testAssetTypeFiltering()
        await testGeographicFiltering()
        
        print("==================================================================================================\n")
        print("Focused tests complete!")
        
        if let session = querySession {
            printSimpleStats(session)
        }
    }
    
    private func setupSession() {
        querySession = QueryLanguageSession()
        print("Session initialized\n")
    }
    
    // Move this OUTSIDE of runFocusedTests() to be a proper class method
    func debugAvailableData() async {
        print("\n🔍 DEBUG: Available Data")
        print(String(repeating: "=", count: 50))
        
        let tool = getHoldingsTool(isSessionStart: true)
        
        // Get ALL holdings to see what's available
        let allHoldings = getHoldingsTool.Arguments(
            intent: "show all",
            filters: [],
            limit: nil
        )
        
        let result = await tool.call(arguments: allHoldings)
        print("ALL HOLDINGS:")
        print(extractToolContent(result))
        
        // Test losing positions filter directly
        let losingTest = getHoldingsTool.Arguments(
            intent: "losing positions",
            filters: [getHoldingsTool.Arguments.SmartFilter(
                field: "marketplpercentinsccy",
                condition: "0",
                filterType: .lessThan
            )],
            limit: nil
        )
        
        let losingResult = await tool.call(arguments: losingTest)
        print("\nLOSING POSITIONS (performance < 0):")
        print(extractToolContent(losingResult))
        
        // Test bonds filter
        let bondsTest = getHoldingsTool.Arguments(
            intent: "show bonds",
            filters: [getHoldingsTool.Arguments.SmartFilter(
                field: "assetclass",
                condition: "Fixed Income",
                filterType: .exact
            )],
            limit: nil
        )
        
        let bondsResult = await tool.call(arguments: bondsTest)
        print("\nBONDS (assetclass = Fixed Income):")
        print(extractToolContent(bondsResult))
    }
    
    func extractToolContent(_ toolOutput: ToolOutput) -> String {
        let description = String(describing: toolOutput)
        if description.hasPrefix("ToolOutput(content: \"") && description.hasSuffix("\")") {
            let start = description.index(description.startIndex, offsetBy: 19)
            let end = description.index(description.endIndex, offsetBy: -2)
            let content = String(description[start..<end])
            return content.replacingOccurrences(of: "\\n", with: "\n")
        }
        return description
    }
        // MARK: - Basic Filtering Tests
        
        func testBasicFiltering() async {
            print("BASIC FILTERING TESTS")
            print("==================================================================================================\n")
            
            await testQuery("Do I own Apple?", expectedBehavior: "Filter by symbol=AAPL")
            await testQuery("Show me MSFT", expectedBehavior: "Filter by symbol=MSFT")
            await testQuery("What's my Tesla position?", expectedBehavior: "Filter by symbol=TSLA")
        }
        
        func testPerformanceFiltering() async {
            print("\nPERFORMANCE FILTERING TESTS")
            print("==================================================================================================\n")
            
            await testQuery("What's gaining money?", expectedBehavior: "Filter performance > 0")
            await testQuery("Show me losing positions", expectedBehavior: "Filter performance < 0")
            await testQuery("My best performer", expectedBehavior: "Filter performance > 0, sort DESC, limit 1")
            await testQuery("Worst performing stock", expectedBehavior: "Filter performance < 0, sort ASC, limit 1")
        }
        
        func testAssetTypeFiltering() async {
            print("\nASSET TYPE FILTERING TESTS")
            print("==================================================================================================\n")
            
            await testQuery("Show me stocks", expectedBehavior: "Filter assetclass=Equity")
            await testQuery("My bonds", expectedBehavior: "Filter assetclass=Fixed Income")
            await testQuery("What equities do I have?", expectedBehavior: "Filter assetclass=Equity")
        }
        
        func testGeographicFiltering() async {
            print("\nGEOGRAPHIC FILTERING TESTS")
            print("==================================================================================================\n")
            
            await testQuery("US holdings", expectedBehavior: "Filter countryregion=United States")
            await testQuery("American stocks", expectedBehavior: "Filter countryregion=United States")
            await testQuery("International positions", expectedBehavior: "Filter countryregion≠United States")
        }
        
        // MARK: - Test Execution
        
        func testQuery(_ query: String, expectedBehavior: String) async {
            print("\n\"\(query)\"")
            print("   Expected: \(expectedBehavior)")
            
            guard let session = querySession else {
                print("Session not initialized")
                return
            }
            
            let startTime = Date()
            
            do {
                let response = try await session.send(query)
                let responseTime = Date().timeIntervalSince(startTime)
                
                if response.isEmpty {
                    print("No response (\(String(format: "%.1f", responseTime))s)")
                } else {
                    print("Response time: \(String(format: "%.1f", responseTime))s")
                    
                    // Debug: Check if tool was actually called
                    if response.contains("getHoldingsTool") || response.contains("[getHoldingsTool]") {
                        print("✅ Tool was called")
                    } else {
                        print("⚠️ Tool may not have been called")
                    }
                    
                    print(response)
                }
                
            } catch {
                let responseTime = Date().timeIntervalSince(startTime)
                print("Error after \(String(format: "%.1f", responseTime))s: \(error.localizedDescription)")
            }
        }
        
        func printSimpleStats(_ session: QueryLanguageSession) {
            let history = session.getConversationHistory()
            print("\nSession Summary:")
            print("- Total queries: \(history.count)")
            
            if !history.isEmpty {
                // Calculate response times based on conversation history timestamps
                var responseTimes: [Double] = []
                
                for i in 0..<history.count {
                    let turn = history[i]
                    
                    if i > 0 {
                        // Time between queries (includes response time + any delay)
                        let previousTurn = history[i-1]
                        let timeDiff = turn.timestamp.timeIntervalSince(previousTurn.timestamp)
                        responseTimes.append(timeDiff)
                    }
                }
                
                if !responseTimes.isEmpty {
                    let avgTime = responseTimes.reduce(0, +) / Double(responseTimes.count)
                    let timeStrings = responseTimes.map { String(format: "%.1fs", $0) }
                    print("- Response times: \(timeStrings.joined(separator: ", "))")
                    print("- Average response time: \(String(format: "%.1f", avgTime))s")
                }
            }
        }
    }
    
    // Even simpler test for quick validation
    @MainActor
    class QuickValidationTest {
        
        func runQuickValidation() async {
            print("Quick Validation Test")
            print("Testing core getHoldings functionality")
            print("==================================================================================================\n")
            
            let session = QueryLanguageSession()
            
            // Just 3 core tests
            let coreTests = [
                ("Do I own Apple?", "Should find AAPL if it exists"),
                ("Show me stocks", "Should filter to Equity asset class"),
                ("What's gaining money?", "Should filter to positive performance")
            ]
            
            for (query, expected) in coreTests {
                print("\n🔍 \(query)")
                print("   \(expected)")
                
                let startTime = Date()
                
                do {
                    let response = try await session.send(query)
                    let responseTime = Date().timeIntervalSince(startTime)
                    
                    print("Response time: \(String(format: "%.1f", responseTime))s")
                    print(response)
                    
                } catch {
                    let responseTime = Date().timeIntervalSince(startTime)
                    print("Error after \(String(format: "%.1f", responseTime))s: \(error.localizedDescription)")
                }
            }
            
            print("\nQuick validation complete")
        }
    }
