import Foundation
import FoundationModels

enum FoundationSummaryClient {

    static func summarizeStructuredContent(_ sections: [DocumentSection]) async throws -> StructuredSummary {
        let session = try await createOptimizedSession()

        let textSummaries = try await summarizeTextSectionsIndividually(sections.filter { $0.type == .paragraph }, session: session)
        let tableSummaries = try await summarizeTableSectionsIndividually(sections.filter { $0.type == .detectedTable }, session: session)
        let listSummary = try await summarizeLists(sections.filter { $0.type == .list }, session: session)
        let headerSummary = try await summarizeHeaders(sections.filter { $0.type == .headerInfo }, session: session)

        // Merge individual results for overall summary
        let mergedText = textSummaries.joined(separator: "\n\n")
        let mergedTables = tableSummaries.joined(separator: "\n\n")

        let overallPrompt = """
        Create a comprehensive executive summary based on this structured content:

        DOCUMENT STRUCTURE:
        \(headerSummary)

        KEY TABLES AND DATA:
        \(mergedTables)

        MAIN CONTENT:
        \(mergedText)

        LISTS AND BULLET POINTS:
        \(listSummary)

        Provide a 3–4 sentence executive summary that captures the main findings, key data points, and actionable insights.
        """

        let overallSummary = try await session.respond(to: overallPrompt)

        return StructuredSummary(
            executiveSummary: overallSummary.content,
            tableSummary: mergedTables,
            textSummary: mergedText,
            listSummary: listSummary,
            documentStructure: headerSummary,
            totalSections: sections.count
        )
    }

    private static func summarizeTextSectionsIndividually(_ textBlocks: [DocumentSection], session: LanguageModelSession) async throws -> [String] {
        var summaries: [String] = []
        for section in textBlocks {
            let prompt = """
            Summarize the following document text in 1–2 sentences:

            Page \(section.pageNumber):
            \(section.content)
            """
            let result = try await session.respond(to: prompt)
            summaries.append(result.content)
        }
        return summaries
    }

    private static func summarizeTableSectionsIndividually(_ tableBlocks: [DocumentSection], session: LanguageModelSession) async throws -> [String] {
        var summaries: [String] = []

        for section in tableBlocks {
            guard let table = section.tableJSON else { continue }

            let tableText = table.map { row in
                row.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
            }.joined(separator: "\n")

            let prompt = """
            Analyze the following table and summarize key figures, trends, or outliers in 1–2 sentences.

            Page \(section.pageNumber):
            \(tableText)
            """

            let result = try await session.respond(to: prompt)
            summaries.append(result.content)
        }

        return summaries
    }

    private static func summarizeLists(_ lists: [DocumentSection], session: LanguageModelSession) async throws -> String {
        guard !lists.isEmpty else { return "No lists found in document." }

        let listContent = lists.map { section in
            "Page \(section.pageNumber): \(section.content)"
        }.joined(separator: "\n\n")

        let prompt = """
        Summarize the following list items. Highlight key actions, patterns, or categories:

        \(listContent)
        """

        let result = try await session.respond(to: prompt)
        return result.content
    }

    private static func summarizeHeaders(_ headers: [DocumentSection], session: LanguageModelSession) async throws -> String {
        guard !headers.isEmpty else { return "Document structure not clearly defined." }

        let headerContent = headers.map { section in
            "Page \(section.pageNumber): \(section.content)"
        }.joined(separator: "\n")

        let prompt = """
        Based on the following headers, outline the document structure and main topics:

        \(headerContent)
        """

        let result = try await session.respond(to: prompt)
        return result.content
    }

    static func summarize(_ text: String) async throws -> String {
        let session = try await createOptimizedSession()
        let prompt = "Summarize this content in 2–3 sentences:\n\n\(text)"
        let result = try await session.respond(to: prompt)
        return result.content
    }

    static func summarizeFinancialDocument(_ sections: [DocumentSection]) async throws -> StructuredSummary {
        return try await summarizeStructuredContent(sections)
    }

    static func summarizeFinancialSection(_ text: String) async throws -> String {
        let session = try await createOptimizedSession()
        let prompt = "Summarize this financial section in 1–2 concise sentences:\n\n\(text)"
        let result = try await session.respond(to: prompt)
        return result.content
    }

    private static func createOptimizedSession() async throws -> LanguageModelSession {
        let session = LanguageModelSession()

        let systemPrompt = """
        You are an expert business analyst specializing in document summarization. 
        Focus on extracting key insights, quantitative data, trends, and actionable recommendations.
        When summarizing tables, highlight important numbers, comparisons, and patterns.
        Keep summaries concise but comprehensive, suitable for executive review.
        """

        _ = try await session.respond(to: systemPrompt)
        return session
    }
}

struct StructuredSummary {
    let executiveSummary: String
    let tableSummary: String
    let textSummary: String
    let listSummary: String
    let documentStructure: String
    let totalSections: Int
}
