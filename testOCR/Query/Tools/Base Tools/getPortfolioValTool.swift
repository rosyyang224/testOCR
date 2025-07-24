//
//  GetPortfolioValTool.swift
//  LocalLLMClientExample
//
//  Created by Rosemary Yang on 7/17/25.
//

import Foundation
import FoundationModels

private func effectiveFilter(_ value: String?) -> String? {
    return (value == "all") ? nil : value
}

struct TrendPoint: Codable {
    let date: String
    let marketValue: Double
}

struct PortfolioValResponse: Codable {
    let portfolio_values: [PortfolioValue]?
    let type: String?
    let portfolio_value: PortfolioValue?
    let points: [TrendPoint]?
}

struct GetPortfolioValTool: Tool {
    static var name: String = "get_portfolio_value"
    let description = "Query your portfolio value snapshots. Filter by date range or index, or retrieve summary statistics like highest, lowest, and trend over time."
    
    @Generable
    struct Arguments {
        @Guide(description: "Start date (inclusive, format YYYY-MM-DD).")
        let startDate: String?
        
        @Guide(description: "End date (inclusive, format YYYY-MM-DD).")
        let endDate: String?
        
        @Guide(description: "Filter for a specific market index (e.g. 'S&P 500').")
        let index: String?
        
        @Guide(description: "Return summary: 'highest', 'lowest', 'trend', or leave blank for raw results.")
        let summary: String?
    }
    
    let portfolioValProvider: @Sendable () -> [PortfolioValue]
    
    init(portfolioValProvider: @escaping @Sendable () -> [PortfolioValue]) {
        self.portfolioValProvider = portfolioValProvider
    }
    
    func call(arguments: Arguments) async throws -> some PromptRepresentable {
        print("[GetPortfolioValTool] called with arguments:")
        print("  startDate: \(arguments.startDate ?? "nil")")
        print("  endDate: \(arguments.endDate ?? "nil")")
        print("  index: \(arguments.index ?? "nil")")
        print("  summary: \(arguments.summary ?? "nil")")

        let all = portfolioValProvider()
        print("[GetPortfolioValTool] total portfolio values: \(all.count)")

        let filtered = all.filter { pv in
            if let idx = effectiveFilter(arguments.index), !pv.indices.contains(where: { $0.localizedCaseInsensitiveContains(idx) }) {
                return false
            }
            if let start = effectiveFilter(arguments.startDate), pv.valueDate < start {
                return false
            }
            if let end = effectiveFilter(arguments.endDate), pv.valueDate > end {
                return false
            }
            return true
        }

        print("[GetPortfolioValTool] filtered values count: \(filtered.count)")

        if let summary = arguments.summary?.lowercased() {
            switch summary {
            case "highest":
                if let maxPV = filtered.max(by: { $0.marketValue < $1.marketValue }) {
                    print("[GetPortfolioValTool] highest found: \(maxPV)")
                    let response = PortfolioValResponse(
                        portfolio_values: nil,
                        type: "highest",
                        portfolio_value: maxPV,
                        points: nil
                    )
                    return try encodeToJSON(response)
                }
            case "lowest":
                if let minPV = filtered.min(by: { $0.marketValue < $1.marketValue }) {
                    print("[GetPortfolioValTool] lowest found: \(minPV)")
                    let response = PortfolioValResponse(
                        portfolio_values: nil,
                        type: "lowest",
                        portfolio_value: minPV,
                        points: nil
                    )
                    return try encodeToJSON(response)
                }
            case "trend":
                let points = filtered
                    .sorted(by: { $0.valueDate < $1.valueDate })
                    .map { TrendPoint(date: $0.valueDate, marketValue: $0.marketValue) }
                print("[GetPortfolioValTool] trend points count: \(points.count)")
                let response = PortfolioValResponse(
                    portfolio_values: nil,
                    type: "trend",
                    portfolio_value: nil,
                    points: points
                )
                return try encodeToJSON(response)
            case "latest":
                print("[GetPortfolioValTool] 'latest' treated as raw data request")
                break // Falls through to return raw filtered data
            default:
                print("[GetPortfolioValTool] Unknown summary type: \(summary)")
                break
            }
        }

        print("[GetPortfolioValTool] returning raw filtered data")
        let response = PortfolioValResponse(
            portfolio_values: filtered,
            type: nil,
            portfolio_value: nil,
            points: nil
        )
        return try encodeToJSON(response)
    }
    
    private func encodeToJSON<T: Codable>(_ data: T) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let jsonData = try encoder.encode(data)
        return String(data: jsonData, encoding: .utf8) ?? "Error encoding portfolio data"
    }
}

func getPortfolioValTool(isSessionStart: Bool = false) -> GetPortfolioValTool {
    guard let container = loadMockDataContainer(from: mockData) else {
        return GetPortfolioValTool { [] }
    }
    
    return GetPortfolioValTool(portfolioValProvider: { container.portfolio_value })
}
