import Foundation
import FoundationModels

enum FoundationJSONSummarizer {
    /// Summarizes a single JSON string into a brief homepage summary.
    static func summarize(_ jsonBlob: String) async throws -> String {
        let session = try await createOptimizedSession()

        let trimmed = jsonBlob.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return "Input JSON is empty."
        }

        let prompt = """
        You are a homepage summarization assistant for a portfolio dashboard.

        Summarize the following JSON data into 2–3 concise sentences for a user-facing homepage.

        Focus on:
        - Overall portfolio performance over time
        - Top performing and underperforming assets
        - Key holdings and shifts in allocation

        Be simple and concise.

        JSON Data:
        \(trimmed)
        """

        let result = try await session.respond(to: prompt)
        return result.content
    }

    private static func createOptimizedSession() async throws -> LanguageModelSession {
        try await LanguageModelSession(
            instructions: Instructions {
                """
                You generate short summaries from structured portfolio data (in JSON).
                Your goal is to help the user quickly understand their portfolio status including top movers, major holdings, and any significant trends.
                Be concise, insightful, and user-friendly.
                Avoid technical jargon unless necessary.
                """
            }
        )
    }
}
