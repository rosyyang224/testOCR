import Foundation
import FoundationModels

struct GetTransactionTool: Tool {
    var name: String { "getTransactions" }

    var description: String {
        "Return transactions filtered by keyword or date."
    }

    @Generable
    struct Arguments {
        @Guide(description: "Optional symbol or description (e.g. AAPL or Tesla)")
        var keyword: String?

        @Guide(description: "Optional date to filter (e.g. 2024-08-01)")
        var date: String?
    }

    func call(arguments: Arguments) async throws -> ToolOutput {
        guard let data = mockData.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let txns = json["transactions"] as? [[String: Any]] else {
            return .init("Failed to load transactions.")
        }

        let filtered = txns.filter { txn in
            let desc = (txn["description"] as? String ?? "").lowercased()
            let sym = (txn["cusip"] as? String ?? "").lowercased()
            let dateMatch = txn["transactiondate"] as? String ?? ""

            let keywordMatch = arguments.keyword == nil || desc.contains(arguments.keyword!.lowercased()) || sym.contains(arguments.keyword!.lowercased())
            let dateFilterMatch = arguments.date == nil || arguments.date == dateMatch

            return keywordMatch && dateFilterMatch
        }

        return ToolOutput(String(describing: filtered))
    }
}
