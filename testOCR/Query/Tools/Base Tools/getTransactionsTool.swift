//
//  GetTransactionsTool.swift
//  LocalLLMClientExample
//
//  Created by Rosemary Yang on 7/17/25.
//

import Foundation
import FoundationModels

private func effectiveFilter(_ value: String?) -> String? {
    return (value == "all") ? nil : value
}

struct TransactionsResponse: Codable {
    let transactions: [Transaction]
    let count: Int
    let total_transactions: Int
}

struct GetTransactionsTool: Tool {
    static var name: String = "get_transactions"
    let description = "Retrieve and filter your transaction history by symbol (CUSIP), transaction type, account, date range, or amount."
    
    @Generable
    struct Arguments {
        @Guide(description: "CUSIP or partial CUSIP of the security.")
        let cusip: String?
        
        @Guide(description: "Transaction type (e.g. 'BUY', 'SELL').")
        let transactiontype: String?
        
        @Guide(description: "Account name (e.g. 'Brokerage Account 1').")
        let account: String?
        
        @Guide(description: "Start date (YYYY-MM-DD, inclusive).")
        let startDate: String?
        
        @Guide(description: "End date (YYYY-MM-DD, inclusive).")
        let endDate: String?
        
        @Guide(description: "Minimum transaction amount.")
        let minTransactionAmt: Double?
        
        @Guide(description: "Maximum transaction amount.")
        let maxTransactionAmt: Double?
    }
    
    let transactionsProvider: @Sendable () -> [Transaction]
    
    init(transactionsProvider: @escaping @Sendable () -> [Transaction]) {
        self.transactionsProvider = transactionsProvider
    }
    
    func call(arguments: Arguments) async throws -> some PromptRepresentable {
        print("[GetTransactionsTool] called with arguments:")
        print("  cusip: \(arguments.cusip ?? "nil")")
        print("  transactiontype: \(arguments.transactiontype ?? "nil")")
        print("  account: \(arguments.account ?? "nil")")
        print("  startDate: \(arguments.startDate ?? "nil")")
        print("  endDate: \(arguments.endDate ?? "nil")")
        print("  minTransactionAmt: \(arguments.minTransactionAmt.map { String(describing: $0) } ?? "nil")")
        print("  maxTransactionAmt: \(arguments.maxTransactionAmt.map { String(describing: $0) } ?? "nil")")

        let all = transactionsProvider()
        print("[GetTransactionsTool] total transactions: \(all.count)")

        let filtered = all.filter { txn in
            if let v = effectiveFilter(arguments.cusip), !txn.cusip.localizedCaseInsensitiveContains(v) { return false }
            if let v = effectiveFilter(arguments.transactiontype), !txn.transactiontype.localizedCaseInsensitiveContains(v) { return false }
            if let v = effectiveFilter(arguments.account), !txn.account.localizedCaseInsensitiveContains(v) { return false }
            if let start = effectiveFilter(arguments.startDate), txn.transactiondate < start { return false }
            if let end = effectiveFilter(arguments.endDate), txn.transactiondate > end { return false }
            if let minAmt = arguments.minTransactionAmt, txn.transactionamt < minAmt { return false }
            if let maxAmt = arguments.maxTransactionAmt, txn.transactionamt > maxAmt { return false }
            return true
        }

        print("[GetTransactionsTool] filtered transactions: \(filtered.count)")
        if filtered.isEmpty {
            print("[GetTransactionsTool] No transactions matched the filters.")
        } else {
            for (i, txn) in filtered.enumerated() {
                print("[GetTransactionsTool] Matched #\(i + 1): \(txn)")
            }
        }

        // Create a response using the external struct
        let response = TransactionsResponse(
            transactions: filtered,
            count: filtered.count,
            total_transactions: all.count
        )

        // Convert to JSON string and return as PromptRepresentable
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let jsonData = try encoder.encode(response)
            let jsonString = String(data: jsonData, encoding: .utf8) ?? "Error encoding transactions data"
            return jsonString
        } catch {
            return "Error serializing transactions: \(error.localizedDescription)"
        }
    }
}

func getTransactionsTool(isSessionStart: Bool = false) -> GetTransactionsTool {
    guard let container = loadMockDataContainer(from: mockData) else {
        return GetTransactionsTool { [] }
    }
    
    return GetTransactionsTool(transactionsProvider: { container.transactions })
}
