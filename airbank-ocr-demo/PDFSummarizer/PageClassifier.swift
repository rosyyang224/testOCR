//
//  PageClassifier.swift
//  airbank-ocr-demo
//
//  Created by Rosemary Yang on 7/3/25.
//  Copyright © 2025 Marek Přidal. All rights reserved.
//
import Foundation
import FoundationModels

enum PageClassifier {
    static func analyzeStructuredDocument(_ sections: [DocumentSection]) async -> DocumentAnalysis {
        do {
            let structuredSummary = try await FoundationSummaryClient.summarizeFinancialDocument(sections)
            
            // Analyze financial document characteristics
            let analysis = await analyzeFinancialDocumentCharacteristics(sections)
            
            return DocumentAnalysis(
                structuredSummary: structuredSummary,
                documentType: analysis.documentType,
                confidence: analysis.confidence,
                keyMetrics: analysis.keyMetrics,
                financialMetrics: analysis.financialMetrics,
                processingTime: Date()
            )
            
        } catch {
            print("Financial document analysis failed: \(error.localizedDescription)")
            
            // Fallback to basic processing with financial context
            let fallbackMetrics = calculateBasicFinancialMetrics(sections)
            
            return DocumentAnalysis(
                structuredSummary: StructuredSummary(
                    executiveSummary: "Financial document analysis failed: \(error.localizedDescription)",
                    tableSummary: "Contains \(fallbackMetrics.tableCount) financial tables",
                    textSummary: "Contains \(fallbackMetrics.textBlockCount) text sections",
                    listSummary: "Contains \(fallbackMetrics.listCount) lists",
                    documentStructure: "Financial document with \(fallbackMetrics.totalSections) sections",
                    totalSections: sections.count,
                    financialSummary: FinancialSummary(
                        portfolioValue: "Unable to calculate",
                        majorHoldings: [],
                        currencyExposure: [],
                        performanceMetrics: [],
                        riskMetrics: []
                    )
                ),
                documentType: .portfolioStatement,
                confidence: 0.3,
                keyMetrics: DocumentMetrics(
                    totalPages: Set(sections.map { $0.pageNumber }).count,
                    tableCount: fallbackMetrics.tableCount,
                    textBlockCount: fallbackMetrics.textBlockCount,
                    listCount: fallbackMetrics.listCount,
                    averageConfidence: 0.3
                ),
                financialMetrics: fallbackMetrics,
                processingTime: Date()
            )
        }
    }
    
    // Legacy compatibility method with financial enhancements
    static func summarizeSections(_ textSections: [String]) async -> (summaries: [String], overall: String) {
        var summaries: [String] = []
        
        for section in textSections {
            do {
                let summary = try await FoundationSummaryClient.summarizeFinancialSection(section)
                summaries.append(summary)
            } catch {
                summaries.append("[Failed to summarize financial section: \(error.localizedDescription)]")
            }
        }
        
        let combined = summaries.joined(separator: "\n\n")
        let overall: String
        
        do {
            overall = try await FoundationSummaryClient.summarizeFinancialDocument(combined)
        } catch {
            overall = "[Failed to create overall financial summary: \(error.localizedDescription)]"
        }
        
        return (summaries, overall)
    }
    
    private static func analyzeFinancialDocumentCharacteristics(_ sections: [DocumentSection]) async -> FinancialDocumentCharacteristics {
        let financialTableCount = sections.filter { $0.type == .financialTable }.count
        let portfolioSummaryCount = sections.filter { $0.type == .portfolioSummary }.count
        let currencyDataCount = sections.filter { $0.type == .currencyData }.count
        let equityHoldingsCount = sections.filter { $0.type == .equityHoldings }.count
        let bondHoldingsCount = sections.filter { $0.type == .bondHoldings }.count
        let derivativesCount = sections.filter { $0.type == .derivativesData }.count
        let chartCount = sections.filter { $0.type == .performanceChart }.count
        let headerCount = sections.filter { $0.type == .headerInfo }.count
        let footerCount = sections.filter { $0.type == .footerDisclaimer }.count
        
        let totalPages = Set(sections.map { $0.pageNumber }).count
        
        // Determine specific financial document type
        let documentType = determineFinancialDocumentType(
            portfolioSummaryCount: portfolioSummaryCount,
            financialTableCount: financialTableCount,
            equityHoldingsCount: equityHoldingsCount,
            bondHoldingsCount: bondHoldingsCount,
            derivativesCount: derivativesCount,
            currencyDataCount: currencyDataCount,
            chartCount: chartCount
        )
        
        // Calculate confidence based on financial data extraction success
        let financialSections = sections.filter { $0.metadata?.isFinancialData == true }
        let highConfidenceSections = sections.filter { $0.confidence > 0.7 }
        let confidence = Double(highConfidenceSections.count) / Double(max(sections.count, 1))
        
        let keyMetrics = DocumentMetrics(
            totalPages: totalPages,
            tableCount: financialTableCount,
            textBlockCount: sections.filter { $0.type == .paragraph }.count,
            listCount: sections.filter { $0.type == .list }.count,
            averageConfidence: confidence
        )
        
        let financialMetrics = FinancialDocumentMetrics(
            totalSections: sections.count,
            financialTableCount: financialTableCount,
            portfolioSummaryCount: portfolioSummaryCount,
            currencyDataCount: currencyDataCount,
            equityHoldingsCount: equityHoldingsCount,
            bondHoldingsCount: bondHoldingsCount,
            derivativesCount: derivativesCount,
            chartCount: chartCount,
            headerCount: headerCount,
            footerCount: footerCount,
            avgFinancialConfidence: financialSections.reduce(0.0) { $0 + Double($1.confidence) } / Double(max(financialSections.count, 1)),
            currencyTypes: extractCurrencyTypes(sections),
            containsPerformanceData: sections.contains { $0.metadata?.hasPercentages == true },
            containsRiskData: sections.contains { section in
                section.content.lowercased().contains("risk") || section.content.lowercased().contains("prr")
            }
        )
        
        return Financial
