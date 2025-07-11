import Foundation
import FoundationModels

struct GetPortfolioValueTool: Tool {
    var name: String { "getPortfolioValue" }

    var description: String {
        "Return portfolio values (optionally filtered by date)."
    }

    @Generable
    struct Arguments {
        @Guide(description: "Optional valueDate to filter for (e.g. 2025-07-01)")
        var date: String?
    }

    func call(arguments: Arguments) async throws -> ToolOutput {
        guard let data = mockData.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let values = json["portfolio_value"] as? [[String: Any]] else {
            return .init("Unable to parse portfolio data.")
        }

        let filtered = values.filter { entry in
            guard let entryDate = entry["valueDate"] as? String else { return false }
            return arguments.date == nil || arguments.date == entryDate
        }

        return ToolOutput(String(describing: filtered))
    }
}
