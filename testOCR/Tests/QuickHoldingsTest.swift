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
    
    // MARK: - Basic Filtering Tests
    
    private func testBasicFiltering() async {
        print("BASIC FILTERING TESTS")
        print("==================================================================================================\n")
        
        await testQuery("Do I own Apple?", expectedBehavior: "Filter by symbol=AAPL")
        await testQuery("Show me MSFT", expectedBehavior: "Filter by symbol=MSFT")
        await testQuery("What's my Tesla position?", expectedBehavior: "Filter by symbol=TSLA")
    }
    
    private func testPerformanceFiltering() async {
        print("\nPERFORMANCE FILTERING TESTS")
        print("==================================================================================================\n")
        
        await testQuery("What's gaining money?", expectedBehavior: "Filter performance > 0")
        await testQuery("Show me losing positions", expectedBehavior: "Filter performance < 0")
        await testQuery("My best performer", expectedBehavior: "Filter performance > 0, sort DESC, limit 1")
        await testQuery("Worst performing stock", expectedBehavior: "Filter performance < 0, sort ASC, limit 1")
    }
    
    private func testAssetTypeFiltering() async {
        print("\nASSET TYPE FILTERING TESTS")
        print("==================================================================================================\n")
        
        await testQuery("Show me stocks", expectedBehavior: "Filter assetclass=Equity")
        await testQuery("My bonds", expectedBehavior: "Filter assetclass=Fixed Income")
        await testQuery("What equities do I have?", expectedBehavior: "Filter assetclass=Equity")
    }
    
    private func testGeographicFiltering() async {
        print("\nGEOGRAPHIC FILTERING TESTS")
        print("==================================================================================================\n")
        
        await testQuery("US holdings", expectedBehavior: "Filter countryregion=United States")
        await testQuery("American stocks", expectedBehavior: "Filter countryregion=United States")
        await testQuery("International positions", expectedBehavior: "Filter countryregion≠United States")
    }
    
    // MARK: - Test Execution
    
    private func testQuery(_ query: String, expectedBehavior: String) async {
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
                print(response)
            }
            
        } catch {
            let responseTime = Date().timeIntervalSince(startTime)
            print("Error after \(String(format: "%.1f", responseTime))s: \(error.localizedDescription)")
        }
    }
    
    private func printSimpleStats(_ session: QueryLanguageSession) {
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
