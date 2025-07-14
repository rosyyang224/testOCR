//import Foundation
//import FoundationModels
//
//struct SummarizeAllocationsTool: Tool {
//    let name = "summarizeAllocations"
//    let description = "Summarize holdings by category: asset class, account type, or currency."
//
//    @Generable
//    struct Arguments {
//        var category: String
//        var date: String
//    }
//
//    func call(arguments: Arguments) async throws -> ToolOutput {
//        let data = try JSONDecoder().decode(MockData.self, from: Data(mockData.utf8))
//
//        let keyPath: (HoldingEntry) -> String = {
//            switch arguments.category.lowercased() {
//            case "asset_class": return { $0.assetclass }
//            case "currency": return { $0.sccy }
//            case "account": return { $0.accounttype }
//            default: return { _ in "Unknown" }
//            }
//        }()
//
//        let breakdown = data.holdings.reduce(into: [String: Double]()) {
//            $0[keyPath($1), default: 0] += $1.totalmarketvaluesccy
//        }
//
//        let parts = breakdown.map {
//            "\($0.key): \(String(format: "%.2f", $0.value))"
//        }.joined(separator: ", ")
//
//        return .init("Allocation by \(arguments.category): \(parts)")
//    }
//}
