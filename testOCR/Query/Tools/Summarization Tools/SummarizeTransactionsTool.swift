//import Foundation
//import FoundationModels
//
//struct SummarizeTransactionsTool: Tool {
//    let name = "summarizeTransactions"
//    let description = "Summarize user's transaction activity by type between two dates."
//
//    @Generable
//    struct Arguments {
//        var startDate: String
//        var endDate: String
//        var categories: [String]?
//    }
//
//    func call(arguments: Arguments) async throws -> ToolOutput {
//        let formatter = ISO8601DateFormatter()
//        guard let startDate = formatter.date(from: arguments.startDate),
//              let endDate = formatter.date(from: arguments.endDate) else {
//            return .init("Invalid date format. Please use ISO8601.")
//        }
//
//        let data = try JSONDecoder().decode(MockData.self, from: Data(mockData.utf8))
//
//        let txns = data.transactions.filter {
//            guard let date = formatter.date(from: $0.transactiondate) else { return false }
//            guard date >= startDate && date <= endDate else { return false }
//            if let cats = arguments.categories {
//                return cats.contains($0.transactiontype.uppercased())
//            }
//            return true
//        }
//
//        guard !txns.isEmpty else {
//            return .init("No transactions found during that period.")
//        }
//
//        var byType = [String: Double]()
//        for txn in txns {
//            let key = txn.transactiontype.uppercased()
//            byType[key, default: 0] += txn.transactionamt
//        }
//
//        let parts = byType.map {
//            "\($0.key): $\(String(format: "%.2f", $0.value))"
//        }.joined(separator: ", ")
//
//        let summary = """
//        From \(formatter.string(from: startDate)) to \(formatter.string(from: endDate)), \
//        you had \(txns.count) transactions totaling: \(parts)
//        """
//        return .init(summary)
//    }
//}
