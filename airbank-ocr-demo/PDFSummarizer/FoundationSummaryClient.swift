//  FoundationSummaryClient.swift
//  airbank-ocr-demo
//
//  Created by Rosemary Yang on 7/2/25.

import Foundation
import FoundationModels

enum FoundationSummaryClient {

    static func summarizeStructuredContent(_ sections: [DocumentSection]) async throws -> StructuredSummary {
        let session = try await createOptimizedSession()

        // Separate content by type for better processing
        let tables = sections.filter { $0.type == .financialTable }
        let textBlocks = sections.filter { $0.type == .paragraph }
        let lists = sections.filter { $0.type == .list }
        let headers = sections.filter { $0.type == .headerInfo }

        async let tableSummary = summarizeTables(tables, session: session)
        async let textSummary = summarizeTextBlocks(textBlocks, session: session)
        async let listSummary = summarizeLists(lists, session: session)
        async let headerSummary = summarizeHeaders(headers, session: session)

        let results = try await (tableSummary, textSummary, listSummary, headerSummary)

        let overallPrompt = """
        Create a comprehensive executive summary based on this structured content:

        DOCUMENT STRUCTURE:
        \(results.3)

        KEY TABLES AND DATA:
        \(results.0)

        MAIN CONTENT:
        \(results.1)

        LISTS AND BULLET POINTS:
        \(results.2)

        Provide a 3-4 sentence executive summary that captures the main findings, key data points, and actionable insights.
        """

        let overallSummary = try await session.respond(to: overallPrompt)

        return StructuredSummary(
            executiveSummary: overallSummary.content,
            tableSummary: results.0,
            textSummary: results.1,
            listSummary: results.2,
            documentStructure: results.3,
            totalSections: sections.count
        )
    }

    static func summarize(_ text: String) async throws -> String {
        let session = try await createOptimizedSession()
        let prompt = "Summarize this content in 2-3 sentences, focusing on key insights and actionable information:\n\n\(text)"
        let result = try await session.respond(to: prompt)
        return result.content
    }

    static func summarizeFinancialDocument(_ sections: [DocumentSection]) async throws -> StructuredSummary {
        return try await summarizeStructuredContent(sections)
    }

    static func summarizeFinancialSection(_ text: String) async throws -> String {
        let session = try await createOptimizedSession()
        let prompt = "Summarize this financial section in 1-2 concise sentences:\n\n\(text)"
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

    private static func summarizeTables(_ tables: [DocumentSection], session: LanguageModelSession) async throws -> String {
        guard !tables.isEmpty else { return "No tables found in document." }

        let tableContent = tables.enumerated().map { index, section in
            "Page \(section.pageNumber) - \(section.content)"
        }.joined(separator: "\n\n")

        let prompt = """
        Analyze these tables and provide a summary focusing on:
        - Key numerical data and trends
        - Important comparisons or changes
        - Notable patterns or outliers

        Tables:
        \(tableContent)
        """

        let result = try await session.respond(to: prompt)
        return result.content
    }

    private static func summarizeTextBlocks(_ textBlocks: [DocumentSection], session: LanguageModelSession) async throws -> String {
        guard !textBlocks.isEmpty else { return "No text content found in document." }

        let groupedText = Dictionary(grouping: textBlocks) { $0.pageNumber }
        let combinedText = groupedText.sorted { $0.key < $1.key }.map { page, sections in
            let pageContent = sections.map { $0.content }.joined(separator: "\n\n")
            return "Page \(page):\n\(pageContent)"
        }.joined(separator: "\n\n---\n\n")

        let prompt = """
        Summarize the main content of this document, focusing on:
        - Primary objectives and conclusions
        - Key findings and recommendations
        - Important context and background

        Content:
        \(combinedText)
        """

        let result = try await session.respond(to: prompt)
        return result.content
    }

    private static func summarizeLists(_ lists: [DocumentSection], session: LanguageModelSession) async throws -> String {
        guard !lists.isEmpty else { return "No lists found in document." }

        let listContent = lists.enumerated().map { index, section in
            "Page \(section.pageNumber) - \(section.content)"
        }.joined(separator: "\n\n")

        let prompt = """
        Summarize these lists and bullet points, highlighting:
        - Key action items or recommendations
        - Important categories or groupings
        - Priority items or critical points

        Lists:
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
        Based on these document headers and structure, describe:
        - Document organization and main sections
        - Flow of information and logical structure
        - Key topics covered

        Headers:
        \(headerContent)
        """

        let result = try await session.respond(to: prompt)
        return result.content
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
