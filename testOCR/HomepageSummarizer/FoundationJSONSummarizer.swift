//
//  FoundationJSONSummarizer.swift
//

import Foundation
import FoundationModels

enum FoundationJSONSummarizer {
    static func summarize(_ jsonBlob: String) async throws -> String {
        let trimmed = jsonBlob.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return "Input JSON is empty."
        }

        let sectionedChunks = try JSONChunker.chunkJSON(trimmed)
        var allSummaries: [String] = []

        for section in sectionedChunks {
            print("New top-level section: \(section.key)")

            var session = try await makeSession(for: section.key)
            var cumulativePromptSize = 0

            for (index, chunk) in section.chunks.enumerated() {
                let prompt = """
                Summarize this chunk of \(section.key):
                \(chunk)
                """

                let promptSize = prompt.count
                cumulativePromptSize += promptSize

                print("[\(section.key) - Chunk \(index + 1)] Prompt size: \(promptSize), Cumulative: \(cumulativePromptSize)")

                if index > 0 && cumulativePromptSize > 4000 {
                    print("Resetting session for \(section.key) at chunk \(index + 1) due to cumulative size.")
                    session = try await makeSession(for: section.key)
                    cumulativePromptSize = promptSize
                }

                let result = try await session.respond(to: prompt)
                print("Summary for \(section.key) chunk #\(index + 1)")
                allSummaries.append(result.content)
            }
        }

        // Final pass: summarize all section summaries
        let summaryText = allSummaries.joined(separator: "\n\n")

        print("Clearing context for final summary aggregation...")
        let finalSession = try await makeFinalAggregationSession()

        print("Final aggregation of \(allSummaries.count) summaries...")

        let finalPrompt = """
        Summarize the following section summaries into a single dashboard-level overview:
        \(summaryText)
        """

        let finalResult = try await finalSession.respond(to: finalPrompt)
        print("🏁 Final summary generated.")
        return finalResult.content
    }

    private static func makeSession(for sectionKey: String) async throws -> LanguageModelSession {
        try await LanguageModelSession(
            instructions: Instructions {
                "Summarize \(sectionKey) data for a portfolio dashboard. Eliminate bullet points and any other formatting."
                "Focus on key metrics, trends, and important details in each chunk. Be concise. Do not add any other information."
            }
        )
    }

    private static func makeFinalAggregationSession() async throws -> LanguageModelSession {
        try await LanguageModelSession(
            instructions: Instructions {
                """
                You are summarizing multiple section-level summaries from a portfolio dashboard.
                Your goal is to extract high-level, concise insights across all data (portfolio value, transactions, holdings).
                Avoid repetition and focus on top insights for a user-facing summary.
                """
            }
        )
    }
}
