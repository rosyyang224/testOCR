//import Foundation
//import FoundationModels
//
//struct SummarizePortfolioValueTool: Tool {
//    let name = "summarizePortfolioValue"
//    let description = """
//    Summarize the user's portfolio value over a specific date range.
//    Provide start and end dates in ISO 8601 format (yyyy-MM-dd).
//    """
//
//    @Generable
//    struct Arguments {
//        let startDate: String
//        let endDate: String
//    }
//
//    func call(arguments: Arguments) async throws -> ToolOutput {
//        print("Calling summarizePortfolioValueTool")
//
//        let formatter = ISO8601DateFormatter()
//        formatter.formatOptions = [.withFullDate]
//
//        guard
//            let startDate = formatter.date(from: arguments.startDate.trimmingCharacters(in: .whitespacesAndNewlines)),
//            let endDate = formatter.date(from: arguments.endDate.trimmingCharacters(in: .whitespacesAndNewlines))
//        else {
//            return .init("Invalid start or end date format. Please use yyyy-MM-dd.")
//        }
//
//        print("Start Date (UTC): \(startDate)")
//        print("End Date (UTC): \(endDate)")
//
//        let data = try JSONDecoder().decode(MockData.self, from: Data(mockData.utf8))
//
//        let entries = data.portfolio_value.compactMap { entry -> PortfolioValueEntry? in
//            guard let entryDate = formatter.date(from: entry.valueDate) else {
//                print("Skipping entry with unparsable valueDate: \(entry.valueDate)")
//                return nil
//            }
//
//            if entryDate >= startDate && entryDate <= endDate {
//                print("Matched valueDate: \(entry.valueDate)")
//                return entry
//            }
//
//            return nil
//        }
//
//        guard !entries.isEmpty else {
//            print("No portfolio value entries found between \(startDate) and \(endDate)")
//            return .init("No portfolio value data found in that range.")
//        }
//
//        let startValue = entries.first!.marketValue
//        let endValue = entries.last!.marketValue
//        let gain = endValue - startValue
//        let pct = (gain / startValue) * 100.0
//
//        let summary = """
//        From \(formatter.string(from: startDate)) to \(formatter.string(from: endDate)), \
//        your portfolio grew from \(String(format: "%.2f", startValue)) to \(String(format: "%.2f", endValue)), \
//        a net gain of \(String(format: "%.2f", gain)) (\(String(format: "%.2f", pct))%).
//        """
//
//        return .init(summary)
//    }
//}
