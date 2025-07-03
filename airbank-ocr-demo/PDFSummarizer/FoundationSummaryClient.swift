// FoundationSummaryClient.swift
import Foundation
import FoundationModels

enum FoundationSummaryClient {
    static func summarize(_ text: String) async throws -> String {
        let session = LanguageModelSession()
        let prompt = "Summarize this in 2 sentences: \n\(text)"
        let result = try await session.respond(to: prompt)
        return result.content
    }
}