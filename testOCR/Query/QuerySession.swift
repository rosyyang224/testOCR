class QuerySession {
    private let session: LanguageModelSession

    init() {
        self.session = LanguageModelSession(
            tools: [MockDataQueryTool()],
            instructions: """
            You are a financial assistant. Use the `mockDataQuery` tool to retrieve user portfolio info.
            You can answer queries about holdings, performance, and transactions.
            """
        )
    }

    func respond(to query: String) async throws -> String {
        try await session.respond(to: query)
    }
}
