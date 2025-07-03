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
        return
