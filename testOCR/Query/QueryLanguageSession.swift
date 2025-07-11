import Foundation
import FoundationModels

@MainActor
class QueryLanguageSession {
    private var session: LanguageModelSession?

    init() {
        session = LanguageModelSession(
            tools: [
                GetPortfolioValueTool(),
                GetTransactionTool(),
                GetHoldingsTool()
            ],
            instructions: """
            You are a financial assistant that answers user questions about their investment portfolio.
            Use the appropriate tool:
            - getPortfolioValue for questions involving performance or value on a specific date.
            - getTransaction for questions about buys, sells, dividends, interest, or any other transaction history.
            - getHoldings for questions about current asset holdings, values, or positions.
            """
        )
    }

    func send(_ query: String) async throws -> String {
        guard let session else {
            throw NSError(domain: "SessionError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Session not initialized"])
        }

        let result = try await session.respond(to: query)
        return result.content
    }
}
