// PageClassifier.swift
import Foundation
import FoundationModels

enum PageClassifier {
    static func summarizeSections(_ sections: [String]) async -> (summaries: [String], overall: String) {
        var summaries: [String] = []

        for section in sections {
            let summary = try? await FoundationSummaryClient.summarize(section)
            summaries.append(summary ?? "[Failed to summarize]")
        }

        let combined = summaries.joined(separator: "\n")
        let overall = (try? await FoundationSummaryClient.summarize(combined)) ?? "[Failed to summarize all]"

        return (summaries, overall)
    }
}
