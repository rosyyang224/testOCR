//
//  FoundationJSONSummarizer.swift
//

import Foundation
import FoundationModels

enum FoundationJSONSummarizer {
    static func summarize(_ jsonBlob: String) async throws -> String {
        print("Starting summarization pipeline...")
        let trimmed = jsonBlob.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return "Input JSON is empty."
        }

        let userData: RawUserData
            do {
                print("Decoding user data...")
                userData = try JSONDecoder().decode(RawUserData.self, from: Data(mockUserData.utf8))
            } catch {
                print("Failed to decode user data: \(error)")
                throw error
            }
        let latestDate = userData.events.compactMap { $0.date }.max() ?? Date()
        let focus = UserPreferences.getUserFocusSummary(from: userData.events, referenceDate: latestDate)

        let topFocus = focus.map { "\($0.topic)" }.joined(separator: ", ")

        let focusContext = """
        You are summarizing a portfolio dashboard for a user. Based on their recent activity, the user appears most interested in: \(topFocus)

        When summarizing the data, prioritize these sections and provide additional insight or granularity for them. Use your judgment to omit or shorten sections the user has shown no interest in.
        """

        print("User preferences computed:")
        focus.forEach { print(" - \($0.topic): \(String(format: "%.4f", $0.score))") }
        print("Injected focusContext into prompt:\n\(focusContext)")
        
        print("Chunking JSON input...")
        let sectionedChunks = try JSONChunker.chunkJSON(trimmed)
        
        
//        var allSummaries: [String] = []
//        let summarizationStart = Date()
//
//        for section in sectionedChunks {
//            print("New top-level section: \(section.key)")
//
//            var session = try await makeSession(for: section.key, focusContext: focusContext)
//            var cumulativePromptSize = 0
//
//            for (index, chunk) in section.chunks.enumerated() {
//                let prompt = """
//                Summarize this chunk of \(section.key):
//                \(chunk)
//                """
//
//                let promptSize = prompt.count
//                cumulativePromptSize += promptSize
//
//                print("[\(section.key) - Chunk \(index + 1)] Prompt size: \(promptSize), Cumulative: \(cumulativePromptSize)")
//
//                if index > 0 && cumulativePromptSize > 4000 {
//                    print("Resetting session for \(section.key) at chunk \(index + 1) due to cumulative size.")
//                    session = try await makeSession(for: section.key, focusContext: focusContext)
//                    cumulativePromptSize = promptSize
//                }
//
//                let result = try await session.respond(to: prompt)
//                print("Summary for \(section.key) chunk #\(index + 1)")
//                allSummaries.append(result.content)
//            }
//        }
//        let summarizationEnd = Date()
//        let summarizationDuration = summarizationEnd.timeIntervalSince(summarizationStart)
//        print("Chunk-level summarization took \(String(format: "%.2f", summarizationDuration)) seconds.")

        
        var orderedAllSummaries = Array(repeating: [String](), count: sectionedChunks.count)
        let summarizationStart = Date()

        do {
                try await withThrowingTaskGroup(of: (Int, [String]).self) { sectionGroup in
                    for (sectionIndex, section) in sectionedChunks.enumerated() {
                        sectionGroup.addTask {
                            print("New top-level section: \(section.key)")

                            let chunkSummaries = try await withThrowingTaskGroup(of: (Int, String).self) { chunkGroup in
                                for (chunkIndex, chunk) in section.chunks.enumerated() {
                                    chunkGroup.addTask {
                                        let session = try await makeSession(for: section.key, focusContext: focusContext)

                                        let prompt = """
                                        Summarize this chunk of \(section.key):
                                        \(chunk)
                                        """

                                        print("[\(section.key) - Chunk \(chunkIndex + 1)] Prompt size: \(prompt.count)")
                                        let result = try await session.respond(to: prompt)
                                        return (chunkIndex, result.content)
                                    }
                                }

                                var ordered = Array(repeating: "", count: section.chunks.count)
                                for try await (chunkIndex, summary) in chunkGroup {
                                    ordered[chunkIndex] = summary
                                }
                                return ordered
                            }

                            return (sectionIndex, chunkSummaries)
                        }
                    }

                    for try await (sectionIndex, chunkSummaries) in sectionGroup {
                        orderedAllSummaries[sectionIndex] = chunkSummaries
                    }
                }
            } catch {
                print("Error during chunk-level summarization: \(error)")
                throw error
            }
        
        let summarizationEnd = Date()
        let summarizationDuration = summarizationEnd.timeIntervalSince(summarizationStart)
        print("Chunk-level summarization took \(String(format: "%.2f", summarizationDuration)) seconds.")

        let allSummaries = orderedAllSummaries.flatMap { $0 }

        let summaryText = allSummaries.joined(separator: "\n\n")

        print("Clearing context for final summary aggregation...")
        
        let finalSession: LanguageModelSession
            do {
                finalSession = try await makeFinalAggregationSession()
            } catch {
                print("Failed to create final aggregation session: \(error)")
                throw error
            }

        print("Final aggregation of \(allSummaries.count) summaries...")

        let finalPrompt = """
        Summarize the following section summaries into a single dashboard-level overview:
        \(summaryText)
        """

        do {
            let finalResult = try await finalSession.respond(to: finalPrompt)
            print("Final summary generated.")
            return finalResult.content
        } catch {
            print("Final summarization step failed: \(error)")
            throw error
        }
    }

    private static func makeSession(for sectionKey: String, focusContext: String) async throws -> LanguageModelSession {
        try await LanguageModelSession(
            instructions: Instructions {
                """
                \(focusContext)

                Summarize \(sectionKey) data for a portfolio dashboard. Eliminate bullet points and any other formatting. Be concise.
                """
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
