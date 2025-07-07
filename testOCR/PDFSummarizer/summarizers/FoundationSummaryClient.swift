import Foundation
import FoundationModels

enum FoundationSummaryClient {
    static func summarize(_ chunks: [String]) async throws -> String {
        let session = try await createOptimizedSession()

        var pageSummaries: [String] = []

        for (i, pageText) in chunks.enumerated() {
            let trimmed = pageText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                print("Page \(i + 1) is empty, skipping.")
                continue
            }

            let prompt = """
            You are an expert at summarizing financial reports.

            Summarize the following content from page \(i + 1). Return as much numerical data as possible. Highlight key insights.

            \(trimmed)
            """
            
            print(prompt)

            let result = try await session.respond(to: prompt)
            pageSummaries.append("Page \(i + 1): \(result.content)")
        }

        return pageSummaries.joined(separator: "\n\n")
    }

    private static func createOptimizedSession() async throws -> LanguageModelSession {
        try await LanguageModelSession(
            instructions: Instructions {
                """
                You are a summarization assistant focused on business and financial documents.
                Your goal is to extract key insights from large text blocks, including tables, bullet points, and reports.
                Avoid repetition and keep your summary sharp and readable.
                """
            }
        )
    }
}
