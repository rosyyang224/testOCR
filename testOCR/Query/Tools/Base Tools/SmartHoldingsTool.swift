//
//  SmartHoldingsTool.swift
//  airbank-ocr-demo
//
//  Created by Rosemary Yang on 7/14/25.
//  Copyright © 2025 Marek Přidal. All rights reserved.
//


import Foundation
import FoundationModels

struct SmartHoldingsTool: Tool {
    let name = "getHoldings"

    let description: String

    init(userContext: UserContext = UserContext(), isSessionStart: Bool = false) {
        // Declare desc variable outside the if blocks
        var desc: String
        
        if isSessionStart {
            // Full context at session start
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
            
            #if DEBUG
            print(context.debugInfo)
            #endif
        } else {
            // Minimal context for subsequent calls
            let context = ContextManager.shared.getOptimizedContext()
            desc = """
            Filter portfolio holdings using learned session context.
            \(context.minimalContext)
            """
        }
        
        // Add userContext information to description
        if !userContext.availableFields.isEmpty {
            desc += """

            Available fields: \(userContext.availableFields.joined(separator: ", "))
            """
        }

        if !userContext.recentQueries.isEmpty {
            desc += """

            Recent context: \(userContext.recentQueries.joined(separator: "; "))
            """
        }

        if let preferences = userContext.preferences {
            desc += """

            User preferences: \(preferences.description)
            """
        }

        // Set the final description
        self.description = desc
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
        guard let jsonData = mockData.data(using: .utf8),
              let parsed = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let holdings = parsed["holdings"] as? [[String: Any]]
        else {
            return .init("❌ Could not parse holdings from mock data.")
        }

        let filtered = holdings.filter { record in
            for filter in arguments.filters {
                guard let rawValue = record[filter.field] else { return false }

                // Normalize both string and numeric fields
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

        let limited = arguments.limit.map { Array(filtered.prefix($0)) } ?? filtered

        guard !limited.isEmpty else {
            return .init("No holdings matched the given filters.")
        }

        let summary = limited.map { record in
            record.map { "\($0.key): \($0.value)" }
                  .joined(separator: ", ")
        }.joined(separator: "\n\n")

        return .init(summary)
    }
}
