import Foundation
import FoundationModels

struct StructuredSummary {
    let executiveSummary: String
    let tableSummary: String
    let textSummary: String
    let listSummary: String
    let documentStructure: String
    let totalSections: Int
}

enum FoundationSummaryClient {
    
    static func summarizeStructuredContent(_ sections: [DocumentSection]) async throws -> StructuredSummary {
        let session = try await createOptimizedSession()

        let textSummaries = try await summarizeTextSectionsIndividually(sections.filter { $0.type == .paragraph }, session: session)
        let tableSummaries = try await summarizeTableSectionsIndividually(sections.filter { $0.type == .contactTable }, session: session)
        let listSummary = try await summarizeLists(sections.filter { $0.type == .list }, session: session)
        let headerSummary = try await summarizeHeaders(sections.filter { $0.type == .header }, session: session)

        // Merge text and table summaries
        let mergedText = textSummaries.joined(separator: "\n\n")
        let mergedTables = tableSummaries.joined(separator: "\n\n")

        let overallPrompt = """
        You are reviewing a financial or business document.

        DOCUMENT STRUCTURE:
        \(headerSummary)

        KEY TABLES AND DATA:
        \(mergedTables)

        MAIN CONTENT:
        \(mergedText)

        LISTS AND BULLET POINTS:
        \(listSummary)

        Provide a 3–4 sentence executive summary highlighting the key figures, business insights, and decisions.
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
            Analyze the following table and summarize key data points, trends, or outliers in 1–2 sentences.

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
        Summarize the following list items. Highlight categories, action items, and patterns:

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
        Based on the following headers, infer the document structure and key sections:

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
//        let session = LanguageModelSession()
//
//        let systemPrompt = """
//        You are an expert document summarizer. Your task is to analyze structured content from scanned financial or business documents.
//        For tables, highlight important metrics and trends. For text, extract the most important insights.
//        Be concise and clear, writing for a business audience.
//        """
//
//        _ = try await session.respond(to: systemPrompt)
        let session = try await LanguageModelSession(
            instructions: Instructions {
                """
                You are an expert document summarizer. Your task is to analyze structured content...
                """
            }
        )
        return session
    }
    
    static func summarizeExistingPDF(named name: String) async throws -> StructuredSummary {
            guard let url = Bundle.main.url(forResource: name, withExtension: "pdf") else {
                throw NSError(domain: "FoundationSummaryClient", code: 404, userInfo: [NSLocalizedDescriptionKey: "Asset PDF not found."])
            }

            let (sections, _) = await DocumentProcessor.extractStructuredContent(from: url)

            guard !sections.isEmpty else {
                throw NSError(domain: "FoundationSummaryClient", code: 400, userInfo: [NSLocalizedDescriptionKey: "No sections found in PDF."])
            }

            return try await summarizeStructuredContent(sections)
        }
}
