////import Foundation
////import FoundationModels
////
////struct GetPortfolioValueTool: Tool {
////    var name: String { "getPortfolioValue" }
////
////    var description: String {
////        "Return portfolio values (optionally filtered by date)."
////    }
////
////    @Generable
////    struct Arguments {
////        @Guide(description: "Optional valueDate to filter for (e.g. 2025-07-01)")
////        var date: String?
////    }
////
////    func call(arguments: Arguments) async throws -> ToolOutput {
////        print("calling getPortfolioValue")
////
////        guard let data = mockData.data(using: .utf8),
////              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
////              let values = json["portfolio_value"] as? [[String: Any]] else {
////            return .init("Unable to parse portfolio data.")
////        }
////
////        print("Loaded portfolio_value entries:", values.count)
////
////        let formatter = ISO8601DateFormatter()
////        formatter.formatOptions = [.withFullDate]
////
////        var filterDate: Date? = nil
////        if let raw = arguments.date, !raw.trimmingCharacters(in: .whitespaces).isEmpty {
////            print("User input date:", raw)
////            if let parsed = formatter.date(from: raw) {
////                filterDate = parsed
////                print("Parsed date as:", parsed)
////            } else {
////                print("Failed to parse user-supplied date:", raw)
////                return .init("Invalid date format. Please use ISO8601 (e.g. 2025-07-01).")
////            }
////        }
////
////        let filtered = values.filter { entry in
////            guard let entryDateStr = entry["valueDate"] as? String,
////                  let entryDate = formatter.date(from: entryDateStr) else {
////                print("Skipping entry with invalid date:", entry["valueDate"] ?? "nil")
////                return false
////            }
////
////            if let filterDate {
////                let sameDay = Calendar.current.isDate(entryDate, inSameDayAs: filterDate)
////                print("Comparing", entryDateStr, "→", entryDate, "with", filterDate, "→ Match:", sameDay)
////                return sameDay
////            } else {
////                return true
////            }
////        }
////
////        print("Matched entries:", filtered.count)
////
////        if filtered.isEmpty {
////            if let date = arguments.date {
////                return ToolOutput("It seems there is no recorded portfolio value for \(date). Would you like to explore other dates or categories for your portfolio analysis?")
////            } else {
////                return ToolOutput("No portfolio values available.")
////            }
////        }
////
////        return ToolOutput(String(describing: filtered))
////    }
////}
//import Foundation
//import FoundationModels
//
//struct GetPortfolioValueTool: Tool {
//    let name = "getPortfolioValue"
//    let description: String
//
//    init() {
//        description = """
//        Return portfolio values (optionally filtered by date). \
//        Today is \(Date().formatted(date: .complete, time: .omitted))
//        """
//    }
//
//    @Generable
//    struct Arguments {
//        @Guide(description: "Return only the portfolio value for this date (e.g. '2025-03-01' or 'last August')")
//        var date: String?
//    }
//
//    func call(arguments: Arguments) async -> ToolOutput {
//        print("calling getportfoliovalue")
//        let data = try! JSONDecoder().decode(MockData.self, from: Data(mockData.utf8))
//
//        // Parse date string
//        var targetDate: String? = nil
//        if let raw = arguments.date {
//            targetDate = parseToExactDate(raw)
//        }
//
//        let filtered = data.portfolio_value.filter { entry in
//            guard let date = targetDate else { return true }
//            return entry.valueDate == date
//        }
//
//        guard !filtered.isEmpty else {
//            return .init("No portfolio value found for \(arguments.date ?? "the requested date").")
//        }
//
//        let summary = filtered.map {
//            "\($0.valueDate): $ \($0.marketValue) (Change: \($0.marketChange))"
//        }.joined(separator: "\n")
//
//        return .init(summary)
//    }
//
//    /// Parses a user-entered date string to ISO "yyyy-MM-dd", supporting natural language
//    private func parseToExactDate(_ raw: String) -> String? {
//        let isoFormatter = ISO8601DateFormatter()
//        isoFormatter.formatOptions = [.withFullDate]
//
//        // Try exact ISO date
//        if let date = isoFormatter.date(from: raw) {
//            return isoFormatter.string(from: date)
//        }
//
//        // Try natural language date (e.g., "last August")
//        if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) {
//            let matches = detector.matches(in: raw, options: [], range: NSRange(location: 0, length: raw.utf16.count))
//            if let date = matches.first?.date {
//                return isoFormatter.string(from: date)
//            }
//        }
//
//        return nil
//    }
//}
