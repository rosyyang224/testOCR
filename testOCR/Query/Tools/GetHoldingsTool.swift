import Foundation
import FoundationModels

struct GetHoldingsTool: Tool {
    var name: String { "getHoldings" }

    var description: String {
        "Return holdings (optionally filtered by symbol, asset class, or country)."
    }

    @Generable
    struct Arguments {
        @Guide(description: "Optional symbol or CUSIP to filter (e.g. AAPL or 037833100)")
        var keyword: String?

        @Guide(description: "Optional asset class filter (e.g. Equity, Fixed Income)")
        var assetClass: String?

        @Guide(description: "Optional country or region (e.g. United States)")
        var country: String?
    }

    func call(arguments: Arguments) async throws -> ToolOutput {
        guard let data = mockData.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let holdings = json["holdings"] as? [[String: Any]] else {
            return .init("Could not load holdings.")
        }

        let filtered = holdings.filter { holding in
            let symbol = (holding["symbol"] as? String ?? "").lowercased()
            let cusip = (holding["cusip"] as? String ?? "").lowercased()
            let asset = (holding["assetclass"] as? String ?? "").lowercased()
            let region = (holding["countryregion"] as? String ?? "").lowercased()

            let keywordMatch = arguments.keyword == nil || symbol.contains(arguments.keyword!.lowercased()) || cusip.contains(arguments.keyword!.lowercased())
            let assetMatch = arguments.assetClass == nil || asset == arguments.assetClass!.lowercased()
            let countryMatch = arguments.country == nil || region.contains(arguments.country!.lowercased())

            return keywordMatch && assetMatch && countryMatch
        }

        return ToolOutput(String(describing: filtered))
    }
}
