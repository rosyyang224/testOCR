//
//  getHoldingsTool.swift
//  airbank-ocr-demo
//
//  Created by Rosemary Yang on 7/14/25.
//  Copyright © 2025 Marek Přidal. All rights reserved.
//

import Foundation
import FoundationModels

struct getHoldingsTool: Tool {
    let description: String
    
    init(userContext: UserContext = UserContext(), isSessionStart: Bool = false) {
        print("callingtool")
        var desc: String
        
        if isSessionStart {
            let context = ContextManager.shared.getOptimizedContext(forceRefresh: true)
            
            desc = """
            Return holdings filtered intelligently based on user intent.
            Current date: \(Date().formatted(date: .complete, time: .omitted))
            
            \(context.fullSessionContext)
            
            NATURAL LANGUAGE PROCESSING:
            - Company names: Use COMPANIES mapping (Apple→AAPL, Tesla→TSLA)
            - Performance: "top performers" → marketplpercentinsccy > 0, sort DESC
            - Asset types: "stocks" → assetclass="Equity", "bonds" → assetclass="Fixed Income"
            - Geography: "US stocks" → countryregion="United States"
            - Position size: "large positions" → sort by totalmarketvalue DESC
            
            Convert natural language to exact field names using SCHEMA mapping.
            """
        } else {
            let context = ContextManager.shared.getOptimizedContext()
            desc = """
            Filter portfolio holdings using learned session context.
            \(context.minimalContext)
            """
        }
        
        // Add userContext information to description
        if !userContext.availableFields.isEmpty {
            desc += "\n\nAvailable fields: \(userContext.availableFields.joined(separator: ", "))"
        }
        
        if !userContext.recentQueries.isEmpty {
            desc += "\n\nRecent context: \(userContext.recentQueries.joined(separator: "; "))"
        }
        
        if let preferences = userContext.preferences {
            desc += "\n\nUser preferences: \(preferences.description)"
        }
        
        self.description = desc
        print("hiiiiiiii")
    }
    
    struct UserContext {
        let availableFields: [String]
        let recentQueries: [String]
        let preferences: UserPreferences?
        
        init(availableFields: [String] = [], recentQueries: [String] = [], preferences: UserPreferences? = nil) {
            self.availableFields = availableFields
            self.recentQueries = recentQueries
            self.preferences = preferences
        }
    }
    
    struct UserPreferences {
        let favoriteRegions: [String]
        let riskTolerance: String
        let investmentStyle: String
        
        var description: String {
            "regions: \(favoriteRegions.joined(separator: ", ")), risk: \(riskTolerance), style: \(investmentStyle)"
        }
    }
    
    @Generable
    struct Arguments {
        /// Natural language intent (e.g., "tech stocks", "dividend paying", "underperforming")
        var intent: String?
        
        /// Specific filters for smart structured matching
        var filters: [SmartFilter]
        
        /// Sorting preference (optional)
        var sortBy: SortOption?
        
        /// Result limit
        var limit: Int?
        
        @Generable
        struct SmartFilter {
            @Guide(description: "Field name (symbol, assetClass, region, sector, etc.)")
            let field: String
            
            @Guide(description: "Value or condition (e.g., 'AAPL', 'Technology', '>1B', 'contains:dividend')")
            let condition: String
            
            @Guide(description: "Filter type: exact, contains, greaterThan, lessThan, etc.")
            let filterType: FilterType
        }
        
        @Generable
        enum FilterType: String {
            case exact, contains, greaterThan, lessThan, startsWith, endsWith
        }
        
        @Generable
        enum SortOption: String {
            case marketCap, performance, alphabetical, sector, region, recent
        }
    }
    
    func call(arguments: Arguments) async -> ToolOutput {
        // Parse mock data
        guard let jsonData = mockData.data(using: .utf8),
              let parsed = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let holdings = parsed["holdings"] as? [[String: Any]] else {
            return .init("Could not parse mock data.")
        }
        
        // Apply filters
        let filtered = holdings.filter { record in
            for filter in arguments.filters {
                guard let rawValue = record[filter.field] else { return false }
                
                let valueStr = String(describing: rawValue).lowercased()
                let condition = filter.condition.lowercased()
                
                switch filter.filterType {
                case .exact:
                    if valueStr != condition { return false }
                case .contains:
                    if !valueStr.contains(condition) { return false }
                case .greaterThan:
                    if let v = Double(valueStr), let target = Double(condition) {
                        if v <= target { return false }
                    } else { return false }
                case .lessThan:
                    if let v = Double(valueStr), let target = Double(condition) {
                        if v >= target { return false }
                    } else { return false }
                case .startsWith:
                    if !valueStr.hasPrefix(condition) { return false }
                case .endsWith:
                    if !valueStr.hasSuffix(condition) { return false }
                }
            }
            return true
        }
        
        // Apply sorting if specified
        var sortedHoldings = filtered
        if let sortBy = arguments.sortBy {
            let actualSortField: String
            switch sortBy {
            case .marketCap: actualSortField = "totalmarketvalue"
            case .performance: actualSortField = "marketplpercentinsccy"
            case .alphabetical: actualSortField = "symbol"
            case .sector: actualSortField = "assetclass"
            case .region: actualSortField = "countryregion"
            case .recent: actualSortField = "symbol"
            }
            
            sortedHoldings = filtered.sorted { record1, record2 in
                guard let value1 = record1[actualSortField],
                      let value2 = record2[actualSortField] else { return false }
                
                if let num1 = value1 as? Double, let num2 = value2 as? Double {
                    return num1 > num2 // Descending by default
                } else {
                    let str1 = String(describing: value1)
                    let str2 = String(describing: value2)
                    return str1 < str2 // Ascending for strings
                }
            }
        }
        
        // Apply limit
        let limited = arguments.limit.map { Array(sortedHoldings.prefix($0)) } ?? sortedHoldings
        
        guard !limited.isEmpty else {
            let availableFields = holdings.first?.keys.sorted().joined(separator: ", ") ?? "none"
            return .init("No holdings matched the given filters. Available fields: \(availableFields)")
        }
        
        // Format results
        let summary = limited.map { record in
            record.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
        }.joined(separator: "\n\n")
        
        print("[getHoldingsTool] Returning \(limited.count) holdings")
        
        return .init(summary)
    }
}
