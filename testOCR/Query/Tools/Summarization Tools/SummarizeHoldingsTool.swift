//import Foundation
//import FoundationModels
//
//struct SummarizeHoldingsTool: Tool {
//    let name = "summarizeHoldings"
//    let description = "Summarize holdings snapshot by asset class using total market value in settlement currency."
//
//    @Generable
//    struct Arguments {
//        var date: String
//    }
//
//    func call(arguments: Arguments) async throws -> ToolOutput {
//        let data = try JSONDecoder().decode(MockData.self, from: Data(mockData.utf8))
//
//        let total = data.holdings.reduce(0.0) { $0 + $1.totalmarketvaluesccy }
//
//        var byAssetClass: [String: (value: Double, percentPLs: [Double])] = [:]
//        for h in data.holdings {
//            let key = h.assetclass
//            byAssetClass[key, default: (0.0, [])].value += h.totalmarketvaluesccy
//            byAssetClass[key]?.percentPLs.append(h.marketplpercentinsccy)
//        }
//
//        let parts = byAssetClass.map { (key, value) in
//            let avgPL = value.percentPLs.reduce(0, +) / Double(value.percentPLs.count)
//            return "\(key): \(String(format: "%.2f", value.value)) (avg PL: \(String(format: "%.2f", avgPL))%)"
//        }.joined(separator: ", ")
//
//        let summary = "Total market value (SCCY): \(String(format: "%.2f", total)). Breakdown by asset class: \(parts)"
//        return .init(summary)
//    }
//}
