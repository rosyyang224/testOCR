//
//  ContextManager.swift
//  PortfolioLLM
//
//  Created by OpenAI on 7/23/25.
//

import Foundation

// MARK: - Lightweight Cached Struct
struct OptimizedContext {
    let compactSchema: String
    let portfolioSummary: String
    let lastUpdated: Date
}

// MARK: - Context Manager
final class ContextManager {
    static let shared = ContextManager()

    private var cached: OptimizedContext?
    private let expirationInterval: TimeInterval = 3600  // 1 hour

    private init() {}

    // MARK: - Public API

    /// Returns cached context, optionally forcing a refresh.
    func getOptimizedContext(forceRefresh: Bool = false) -> OptimizedContext {
        if forceRefresh || isExpired {
            refreshContext()
        }

        return cached ?? OptimizedContext(
            compactSchema: "ERROR: Context unavailable",
            portfolioSummary: "ERROR: No portfolio data found",
            lastUpdated: Date.distantPast
        )
    }

    func invalidateCache() {
        cached = nil
    }

    func getContextSummaryStats() -> String {
        let context = getOptimizedContext()
        return """
        Schema size: \(context.compactSchema.count) chars
        Summary size: \(context.portfolioSummary.count) chars
        Last updated: \(format(context.lastUpdated))
        """
    }

    // MARK: - Private Helpers

    private var isExpired: Bool {
        guard let last = cached?.lastUpdated else { return true }
        return Date().timeIntervalSince(last) > expirationInterval
    }

    private func refreshContext() {
        do {
            let parsed = try JSONAnalysisUtils.parseJSON(mockData)
            let holdings = try JSONAnalysisUtils.extractHoldings(from: parsed)

            let schema = summarizeSchema(from: holdings)
            let summary = summarizePortfolio(from: holdings)

            cached = OptimizedContext(
                compactSchema: schema,
                portfolioSummary: summary,
                lastUpdated: Date()
            )
        } catch {
            cached = OptimizedContext(
                compactSchema: "ERROR: \(error.localizedDescription)",
                portfolioSummary: "ERROR: Summary generation failed",
                lastUpdated: Date()
            )
        }
    }

    private func summarizeSchema(from holdings: [[String: Any]]) -> String {
        let analysis = JSONAnalysisUtils.analyzeFields(in: holdings)
        let fieldLines = analysis.map { key, stats in
            let optional = stats.isRequired ? "" : "?"
            return "\(key)(\(stats.type.compactName)\(optional))→\(stats.nlHint)"
        }.sorted()

        return "FIELDS: " + fieldLines.joined(separator: ", ")
    }

    private func summarizePortfolio(from holdings: [[String: Any]]) -> String {
        let symbols = holdings.compactMap { $0["symbol"] as? String }
        let companies = JSONAnalysisUtils.extractCompanyMappings(from: holdings)
        let assetClasses = Set(holdings.compactMap { $0["assetclass"] as? String }).sorted()
        let regions = Set(holdings.compactMap { $0["countryregion"] as? String }).sorted()

        return """
        SYMBOLS: \(symbols.joined(separator: ","))
        COMPANIES: \(companies.joined(separator: ","))
        ASSETS: \(assetClasses.joined(separator: ","))
        REGIONS: \(regions.joined(separator: ","))
        """
    }
}
