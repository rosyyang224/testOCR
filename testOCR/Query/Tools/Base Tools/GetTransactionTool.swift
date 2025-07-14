////import Foundation
////import FoundationModels
////
////struct GetTransactionTool: Tool {
////    var name: String { "getTransactions" }
////
////    var description: String {
////        "Return transactions filtered by keyword or natural language date (e.g. 'last September')."
////    }
////
////    @Generable
////    struct Arguments {
////        @Guide(description: "Optional symbol or description (e.g. AAPL or Tesla)")
////        var keyword: String?
////
////        @Guide(description: "Optional date or time (e.g. 2024-08, August 2024, last September)")
////        var date: String?
////    }
////
////    func call(arguments: Arguments) async throws -> ToolOutput {
////        print("calling getTransactions")
////
////        guard let data = mockData.data(using: .utf8),
////              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
////              let txns = json["transactions"] as? [[String: Any]] else {
////            return .init("Failed to load transactions.")
////        }
////
////        print("Loaded transaction entries:", txns.count)
////
////        // Parse user-supplied date using DateParser
////        var targetDate: Date? = nil
////        var granularity: Calendar.Component = .day
////
////        if let raw = arguments.date, !raw.trimmingCharacters(in: .whitespaces).isEmpty {
////            print("User input date:", raw)
////            targetDate = DateParser.parse(raw)
////            granularity = DateParser.detectGranularity(raw)
////            if let parsed = targetDate {
////                print("Parsed date:", parsed, "→ granularity:", granularity)
////            } else {
////                return .init("Could not understand the date \"\(raw)\". Please try a different format like '2024', '2024-08', or 'last September'.")
////            }
////        }
////
////        let calendar = Calendar.current
////        let filtered = txns.filter { txn in
////            let desc = (txn["description"] as? String ?? "").lowercased()
////            let sym = (txn["cusip"] as? String ?? "").lowercased()
////            let dateStr = txn["transactiondate"] as? String ?? ""
////
////            let keywordMatch = arguments.keyword == nil || desc.contains(arguments.keyword!.lowercased()) || sym.contains(arguments.keyword!.lowercased())
////
////            guard let txnDate = ISO8601DateFormatter().date(from: dateStr) else {
////                print("Skipping invalid transactiondate:", dateStr)
////                return false
////            }
////
////            let dateMatch = targetDate == nil || calendar.isDate(txnDate, equalTo: targetDate!, toGranularity: granularity)
//////
////            return keywordMatch && dateMatch
////        }
////
////        print("Matched entries:", filtered.count)
////
////        return filtered.isEmpty
////            ? .init("No matching transactions found for your filters.")
////            : .init(String(describing: filtered))
////    }
////}
//
//import Foundation
//import FoundationModels
//
//struct GetTransactionTool: Tool {
//    let name = "getTransactions"
//    let description: String
//
//    init() {
//        description = """
//        Return transactions (optionally filtered by symbol, transaction type, date, account, or currency). \
//        Today is \(Date().formatted(date: .complete, time: .omitted))
//        """
//    }
//
//    @Generable
//    struct Arguments {
//        @Guide(description: "Asset name or CUSIP (e.g. 'Apple', '037833100')")
//        var symbol: String?
//
//        @Guide(description: "Transaction type (e.g. 'BUY', 'SELL', 'DIVIDEND', 'INTEREST')")
//        var transactionType: String?
//
//        @Guide(description: "Transaction date (e.g. '2024-06-30' or 'last June')")
//        var date: String?
//
//        @Guide(description: "Account name (e.g. 'Brokerage Account 1')")
//        var account: String?
//
//        @Guide(description: "Currency code (e.g. 'USD')")
//        var currency: String?
//    }
//
//    func call(arguments: Arguments) async -> ToolOutput {
//        print("calling gettransactions")
//        let data = try! JSONDecoder().decode(MockData.self, from: Data(mockData.utf8))
//        let targetDate = arguments.date.flatMap { parseToExactDate($0) }
//
//        let filtered = data.transactions.filter { txn in
//            let symbolMatch = arguments.symbol.map {
//                txn.description.localizedCaseInsensitiveContains($0) ||
//                txn.cusip.localizedCaseInsensitiveContains($0)
//            } ?? true
//
//            let typeMatch = arguments.transactionType.map {
//                txn.transactiontype.caseInsensitiveCompare($0) == .orderedSame
//            } ?? true
//
//            let dateMatch = targetDate.map {
//                txn.transactiondate == $0
//            } ?? true
//
//            let accountMatch = arguments.account.map {
//                txn.account.caseInsensitiveCompare($0) == .orderedSame
//            } ?? true
//
//            let currencyMatch = arguments.currency.map {
//                txn.stccy.caseInsensitiveCompare($0) == .orderedSame
//            } ?? true
//
//            return symbolMatch && typeMatch && dateMatch && accountMatch && currencyMatch
//        }
//
//        guard !filtered.isEmpty else {
//            return .init("No transactions matched the given filters.")
//        }
//
//        let summary = filtered.map {
//            "\($0.transactiondate): [\($0.transactiontype)] \($0.description) – \($0.transactionamt) \($0.stccy) in \($0.account)"
//        }.joined(separator: "\n")
//
//        return .init(summary)
//    }
//
//    private func parseToExactDate(_ raw: String) -> String? {
//        let isoFormatter = ISO8601DateFormatter()
//        isoFormatter.formatOptions = [.withFullDate]
//
//        if let date = isoFormatter.date(from: raw) {
//            return isoFormatter.string(from: date)
//        }
//
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
