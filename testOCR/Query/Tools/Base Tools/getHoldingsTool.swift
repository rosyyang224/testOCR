//
//  GetHoldingsTool.swift
//  LocalLLMClientExample
//
//  Created by Rosemary Yang on 7/17/25.
//

import Foundation
import FoundationModels

private func effectiveFilter(_ value: String?) -> String? {
    return (value == "all") ? nil : value
}

struct HoldingsResponse: Codable {
    let holdings: [Holding]
    let count: Int
    let total_holdings: Int
}

struct GetHoldingsTool: Tool {
    let name = "get_holdings"
    let description = "Retrieve portfolio holdings, filterable by symbol, asset class, region, account type, profit/loss, or value."
    
    @Generable
    struct Arguments {
        @Guide(description: "The security symbol (e.g. 'AAPL').")
        let symbol: String?
        
        @Guide(description: "Asset class (e.g. 'Equity', 'Fixed Income').")
        let assetclass: String?
        
        @Guide(description: "Country or region (e.g. 'United States', 'Hong Kong').")
        let countryregion: String?
        
        @Guide(description: "Account type (e.g. 'Brokerage', 'Retirement').")
        let accounttype: String?
        
        @Guide(description: "Only holdings with profit/loss (in settlement currency) >= this value.")
        let min_marketplinsccy: Double?
        
        @Guide(description: "Only holdings with profit/loss (in settlement currency) <= this value.")
        let max_marketplinsccy: Double?
        
        @Guide(description: "Only holdings with market value (in base currency) >= this value.")
        let min_marketvalueinbccy: Double?
        
        @Guide(description: "Only holdings with market value (in base currency) <= this value.")
        let max_marketvalueinbccy: Double?
    }
    
    let holdingsProvider: @Sendable () -> [Holding]
    
    init(holdingsProvider: @escaping @Sendable () -> [Holding]) {
        self.holdingsProvider = holdingsProvider
    }
    
    func call(arguments: Arguments) async throws -> ToolOutput {
        print("[GetHoldingsTool] called with arguments:")
        print("  symbol: \(arguments.symbol ?? "nil")")
        print("  assetclass: \(arguments.assetclass ?? "nil")")
        print("  countryregion: \(arguments.countryregion ?? "nil")")
        print("  accounttype: \(arguments.accounttype ?? "nil")")
        print("  min_marketplinsccy: \(arguments.min_marketplinsccy.map { String(describing: $0) } ?? "nil")")
        print("  max_marketplinsccy: \(arguments.max_marketplinsccy.map { String(describing: $0) } ?? "nil")")
        print("  min_marketvalueinbccy: \(arguments.min_marketvalueinbccy.map { String(describing: $0) } ?? "nil")")
        print("  max_marketvalueinbccy: \(arguments.max_marketvalueinbccy.map { String(describing: $0) } ?? "nil")")

        let all = holdingsProvider()
        print("[GetHoldingsTool] total holdings: \(all.count)")

        let filtered = all.filter { h in
            if let v = effectiveFilter(arguments.symbol), !h.symbol.localizedCaseInsensitiveContains(v) { return false }
            if let v = effectiveFilter(arguments.assetclass), !h.assetclass.localizedCaseInsensitiveContains(v) { return false }
            if let v = effectiveFilter(arguments.countryregion), !h.countryregion.localizedCaseInsensitiveContains(v) { return false }
            if let v = effectiveFilter(arguments.accounttype), !h.accounttype.localizedCaseInsensitiveContains(v) { return false }
            if let minPL = arguments.min_marketplinsccy, h.marketplinsccy < minPL { return false }
            if let maxPL = arguments.max_marketplinsccy, h.marketplinsccy > maxPL { return false }
            if let minVal = arguments.min_marketvalueinbccy, h.marketvalueinbccy < minVal { return false }
            if let maxVal = arguments.max_marketvalueinbccy, h.marketvalueinbccy > maxVal { return false }
            return true
        }

        print("[GetHoldingsTool] filtered holdings: \(filtered.count)")
        if filtered.isEmpty {
            print("[GetHoldingsTool] No holdings matched the filters.")
        } else {
            for (i, holding) in filtered.enumerated() {
                print("[GetHoldingsTool] Matched #\(i + 1): \(holding)")
            }
        }

        // Create a response using the external struct
        let response = HoldingsResponse(
            holdings: filtered,
            count: filtered.count,
            total_holdings: all.count
        )

        // Convert to JSON string and return as PromptRepresentable
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let jsonData = try encoder.encode(response)
            let jsonString = String(data: jsonData, encoding: .utf8) ?? "Error encoding holdings data"
            return ToolOutput(jsonString)
        } catch {
            return ToolOutput("Error serializing holdings: \(error.localizedDescription)")
        }
    }
}

// Factory function to create the tool (matching your existing pattern)
func getHoldingsTool(isSessionStart: Bool = false) -> GetHoldingsTool {
    // Load mock data using your existing approach
    guard let container = loadMockDataContainer(from: mockData) else {
        return GetHoldingsTool { [] }
    }
    
    return GetHoldingsTool(holdingsProvider: { container.holdings })
}

// Helper function for loading mock data (if not already defined elsewhere)
func loadMockDataContainer(from jsonString: String) -> MockDataContainer? {
    let data = Data(jsonString.utf8)
    let decoder = JSONDecoder()
    do {
        return try decoder.decode(MockDataContainer.self, from: data)
    } catch {
        print("Failed to decode mock data: \(error)")
        return nil
    }
}

////
////  getHoldingsTool.swift
////  airbank-ocr-demo
////
////  Created by Rosemary Yang on 7/14/25.
////  Copyright © 2025 Marek Přidal. All rights reserved.
////
//
//import Foundation
//import FoundationModels
//
//struct getHoldingsTool: Tool {
//    let description: String
//    
//    init(userContext: UserContext = UserContext(), isSessionStart: Bool = false) {
//        let context = ContextManager.shared.getOptimizedContext(forceRefresh: isSessionStart)
//        
//        var desc = """
//        
//        """
//        
//        // Add minimal user context if available
//        if !userContext.availableFields.isEmpty {
//            desc += "\n\nRecent fields used: \(userContext.availableFields.prefix(5).joined(separator: ", "))"
//        }
//        
//        self.description = desc
//    }
//    
//    struct UserContext {
//        let availableFields: [String]
//        let recentQueries: [String]
//        let preferences: UserPreferences?
//        
//        init(availableFields: [String] = [], recentQueries: [String] = [], preferences: UserPreferences? = nil) {
//            self.availableFields = availableFields
//            self.recentQueries = recentQueries
//            self.preferences = preferences
//        }
//    }
//    
//    struct UserPreferences {
//        let favoriteRegions: [String]
//        let riskTolerance: String
//        let investmentStyle: String
//        
//        var description: String {
//            "regions: \(favoriteRegions.joined(separator: ", ")), risk: \(riskTolerance), style: \(investmentStyle)"
//        }
//    }
//    
//    @Generable
//    struct Arguments {
//        /// Natural language query (e.g., "show me Apple's performance", "tech stocks that are losing money")
//        var query: String
//        
//        /// Optional result limit
//        var limit: Int?
//    }
//    
//    func call(arguments: Arguments) async -> ToolOutput {
//        do {
//            let jsonString = mockData
//            let parsed = try JSONAnalysisUtils.parseJSON(jsonString)
//            let holdings = try JSONAnalysisUtils.extractHoldings(from: parsed)
//            
//            print("[GetHoldingsTool] Processing query: '\(arguments.query)' on \(holdings.count) holdings")
//            
//            // Use NLP processor to understand the query and generate filters
//            let queryResult = processNaturalLanguageQuery(
//                arguments.query,
//                holdings: holdings
//            )
//            
//            guard !queryResult.filteredHoldings.isEmpty else {
//                let fieldAnalysis = JSONAnalysisUtils.analyzeFields(in: holdings)
//                let availableFields = fieldAnalysis.keys.sorted().joined(separator: ", ")
//                return .init("No holdings matched your query '\(arguments.query)'. Available data fields: \(availableFields)")
//            }
//            
//            // Apply limit if specified
//            let limited = arguments.limit.map {
//                Array(queryResult.filteredHoldings.prefix($0))
//            } ?? queryResult.filteredHoldings
//            
//            // Format results
//            let summary = formatResults(
//                limited,
//                query: arguments.query,
//                intent: queryResult.intent,
//                allHoldings: holdings
//            )
//            
//            print("[GetHoldingsTool] Returning \(limited.count) holdings for intent: \(queryResult.intent)")
//            
//            return .init(summary)
//            
//        } catch let error as JSONAnalysisError {
//            return .init("JSON Analysis Error: \(error.localizedDescription)")
//        } catch {
//            return .init("Unexpected error: \(error.localizedDescription)")
//        }
//    }
//    
//    // MARK: - Natural Language Processing
//    
//    private struct QueryResult {
//        let filteredHoldings: [[String: Any]]
//        let intent: QueryIntent
//        let matchedCompanies: [String]
//    }
//    
//    private func processNaturalLanguageQuery(_ query: String, holdings: [[String: Any]]) -> QueryResult {
//        let intent = NaturalLanguageProcessor.identifyQueryIntent(from: query)
//        let companyNames = NaturalLanguageProcessor.extractCompanyNamesFromQuery(query)
//        let availableSymbols = holdings.compactMap { $0["symbol"] as? String }
//        
//        // 4. Resolve company names to symbols (this is where you'd call foundation model)
//        var resolvedSymbols: [String] = []
//        for companyName in companyNames {
//            if let symbol = resolveCompanyToSymbol(companyName, availableSymbols: availableSymbols) {
//                resolvedSymbols.append(symbol)
//            }
//        }
//        
//        // 5. Apply semantic filters based on intent and resolved companies
//        let filtered = applySemanticFilters(
//            to: holdings,
//            intent: intent,
//            query: query,
//            targetSymbols: resolvedSymbols
//        )
//        
//        return QueryResult(
//            filteredHoldings: filtered,
//            intent: intent,
//            matchedCompanies: resolvedSymbols
//        )
//    }
//    
//    private func applySemanticFilters(
//        to holdings: [[String: Any]],
//        intent: QueryIntent,
//        query: String,
//        targetSymbols: [String]
//    ) -> [[String: Any]] {
//        
//        var filtered = holdings
//        let lowercasedQuery = query.lowercased()
//        
//        // Filter by specific companies if mentioned
//        if !targetSymbols.isEmpty {
//            filtered = filtered.filter { holding in
//                guard let symbol = holding["symbol"] as? String else { return false }
//                return targetSymbols.contains(symbol)
//            }
//        }
//        
//        // Apply intent-based filters
//        switch intent {
//        case .performance:
//            if lowercasedQuery.contains("positive") || lowercasedQuery.contains("gaining") || lowercasedQuery.contains("winning") {
//                filtered = filtered.filter { holding in
//                    (holding["marketplpercentinsccy"] as? Double ?? 0) > 0
//                }
//            } else if lowercasedQuery.contains("negative") || lowercasedQuery.contains("losing") || lowercasedQuery.contains("underperforming") {
//                filtered = filtered.filter { holding in
//                    (holding["marketplpercentinsccy"] as? Double ?? 0) < 0
//                }
//            }
//            // Sort by performance
//            filtered = filtered.sorted { holding1, holding2 in
//                let perf1 = holding1["marketplpercentinsccy"] as? Double ?? 0
//                let perf2 = holding2["marketplpercentinsccy"] as? Double ?? 0
//                return perf1 > perf2
//            }
//            
//        case .assetAllocation:
//            if lowercasedQuery.contains("stocks") || lowercasedQuery.contains("equity") {
//                filtered = filtered.filter { holding in
//                    (holding["assetclass"] as? String)?.lowercased().contains("equity") == true
//                }
//            } else if lowercasedQuery.contains("bonds") || lowercasedQuery.contains("fixed") {
//                filtered = filtered.filter { holding in
//                    let assetClass = (holding["assetclass"] as? String)?.lowercased() ?? ""
//                    return assetClass.contains("fixed") || assetClass.contains("bond")
//                }
//            }
//            
//        case .geographicAnalysis:
//            if lowercasedQuery.contains("us") || lowercasedQuery.contains("american") {
//                filtered = filtered.filter { holding in
//                    (holding["countryregion"] as? String)?.lowercased().contains("united states") == true
//                }
//            } else if lowercasedQuery.contains("international") || lowercasedQuery.contains("foreign") {
//                filtered = filtered.filter { holding in
//                    (holding["countryregion"] as? String)?.lowercased().contains("united states") == false
//                }
//            }
//            
//        case .summaryAnalysis:
//            if lowercasedQuery.contains("largest") || lowercasedQuery.contains("biggest") {
//                filtered = filtered.sorted { holding1, holding2 in
//                    let value1 = holding1["totalmarketvalue"] as? Double ?? 0
//                    let value2 = holding2["totalmarketvalue"] as? Double ?? 0
//                    return value1 > value2
//                }
//            }
//            
//        default:
//            // For other intents, rely on company filtering and basic relevance
//            break
//        }
//        
//        return filtered
//    }
//    
//    /// Resolves company names to symbols - in production, this would call a foundation model
//    private func resolveCompanyToSymbol(_ companyName: String, availableSymbols: [String]) -> String? {
//        // This is where you'd call your foundation model:
//        // let prompt = "Convert '\(companyName)' to stock symbol. Available: \(availableSymbols.joined(separator: ", "))"
//        // return await foundationModel.query(prompt)
//        
//        // Basic fallback mapping for demo
//        let lowercased = companyName.lowercased()
//        let mapping: [String: String] = [
//            "apple": "AAPL",
//            "tesla": "TSLA",
//            "google": "GOOGL",
//            "alphabet": "GOOGL",
//            "alibaba": "9988.HK",
//            "microsoft": "MSFT",
//            "amazon": "AMZN"
//        ]
//        
//        let symbol = mapping[lowercased]
//        return availableSymbols.contains(symbol ?? "") ? symbol : nil
//    }
//    
//    // MARK: - Result Formatting
//    
//    private func formatResults(
//        _ holdings: [[String: Any]],
//        query: String,
//        intent: QueryIntent,
//        allHoldings: [[String: Any]]
//    ) -> String {
//        
//        // Build company mappings for display
//        let companyMappings = NaturalLanguageProcessor.extractCompanyMappings(from: allHoldings)
//        let mappingDict = Dictionary(uniqueKeysWithValues: companyMappings.compactMap { mapping in
//            let parts = mapping.components(separatedBy: "=")
//            return parts.count == 2 ? (parts[1], parts[0]) : nil
//        })
//        
//        var summary = "Results for: \"\(query)\"\n"
//        summary += "Found \(holdings.count) matching holdings\n\n"
//        
//        for (index, holding) in holdings.enumerated() {
//            if index > 0 { summary += "\n" }
//            
//            var lines: [String] = []
//            
//            // Symbol and company name
//            if let symbol = holding["symbol"] {
//                let symbolStr = String(describing: symbol)
//                let company = mappingDict[symbolStr] ?? symbolStr
//                lines.append("🏢 \(company) (\(symbolStr))")
//            }
//            
//            // Key metrics based on intent
//            switch intent {
//            case .performance:
//                if let performance = holding["marketplpercentinsccy"] as? Double {
//                    let perfStr = String(format: "%.2f%%", performance)
//                    let icon = performance >= 0 ? "📈" : "📉"
//                    lines.append("\(icon) Performance: \(perfStr)")
//                }
//                if let marketValue = holding["totalmarketvalue"] {
//                    lines.append("💰 Value: $\(marketValue)")
//                }
//                
//            case .assetAllocation, .geographicAnalysis:
//                if let assetClass = holding["assetclass"] {
//                    lines.append("📊 Asset: \(assetClass)")
//                }
//                if let region = holding["countryregion"] {
//                    lines.append("🌍 Region: \(region)")
//                }
//                if let marketValue = holding["totalmarketvalue"] {
//                    lines.append("💰 Value: $\(marketValue)")
//                }
//                
//            default:
//                // General format
//                if let assetClass = holding["assetclass"] {
//                    lines.append("📊 \(assetClass)")
//                }
//                if let marketValue = holding["totalmarketvalue"] {
//                    lines.append("💰 $\(marketValue)")
//                }
//                if let performance = holding["marketplpercentinsccy"] as? Double {
//                    let perfStr = String(format: "%.2f%%", performance)
//                    lines.append("📈 \(perfStr)")
//                }
//            }
//            
//            summary += lines.joined(separator: " | ")
//        }
//        
//        return summary
//    }
//}
