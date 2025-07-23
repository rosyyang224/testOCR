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

func getHoldingsTool(isSessionStart: Bool = false) -> GetHoldingsTool {
    guard let container = loadMockDataContainer(from: mockData) else {
        return GetHoldingsTool { [] }
    }
    
    return GetHoldingsTool(holdingsProvider: { container.holdings })
}

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
