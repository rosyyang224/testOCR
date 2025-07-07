import Foundation
import FoundationModels

enum FoundationSummaryClient {
    
    static func summarize(_ fullText: String) async throws -> String {
        let session = try await createOptimizedSession()

        let prompt = """
        You are an expert at summarizing financial and business documents.

        Summarize the following content in 3–4 clear, concise sentences. Highlight any key insights, figures, or trends:

        \(fullText)
        """

        let result = try await session.respond(to: prompt)
        return result.content
    }

    private static func createOptimizedSession() async throws -> LanguageModelSession {
        let session = try await LanguageModelSession(
            instructions: Instructions {
                """
                You are a summarization assistant focused on business and financial documents.
                Your goal is to extract key insights from large text blocks, including tables, bullet points, and reports.
                Avoid repetition and keep your summary sharp and readable.
                """
            }
        )
        return session
    }
}
