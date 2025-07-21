//
//  PortfolioPerformanceTool.swift
//  airbank-ocr-demo
//
//  Created by Rosemary Yang on 7/15/25.
//  Copyright © 2025 Marek Přidal. All rights reserved.
//


import Foundation

// MARK: - Portfolio Performance Tool

class getPortfolioValTool {
    static let shared = getPortfolioValTool()
    
    private init() {}
    
    // MARK: - Main Performance Retrieval
    
    func getPerformanceData(query: String) -> PerformanceResult {
        do {
            let parsed = try JSONAnalysisUtils.parseJSON(mockData)
            let portfolioData = try extractPortfolioData(from: parsed)
            
            let analyzer = PerformanceAnalyzer(portfolioData: portfolioData)
            return analyzer.analyze(query: query.lowercased())
            
        } catch {
            return PerformanceResult(
                success: false,
                data: [:],
                message: "Error: \(error.localizedDescription)"
            )
        }
    }
    
    // MARK: - Quick Access Methods
    
    func getCurrentPerformance() -> PerformanceResult {
        return getPerformanceData(query: "current performance")
    }
    
    func getYearToDatePerformance() -> PerformanceResult {
        return getPerformanceData(query: "year to date performance")
    }
    
    func getPerformanceTrend() -> PerformanceResult {
        return getPerformanceData(query: "performance trend")
    }
    
    // MARK: - Private Helpers
    
    private func extractPortfolioData(from parsed: [String: Any]) throws -> [PortfolioSnapshot] {
        guard let portfolioArray = parsed["portfolio_value"] as? [[String: Any]] else {
            throw PerformanceError.missingData("Portfolio value data not found")
        }
        
        return portfolioArray.compactMap { dict in
            PortfolioSnapshot(from: dict)
        }.sorted { $0.valueDate < $1.valueDate }
    }
}

// MARK: - Performance Analyzer

class PerformanceAnalyzer {
    private let portfolioData: [PortfolioSnapshot]
    
    init(portfolioData: [PortfolioSnapshot]) {
        self.portfolioData = portfolioData
    }
    
    func analyze(query: String) -> PerformanceResult {
        if query.contains("current") {
            return getCurrentMetrics()
        } else if query.contains("year") || query.contains("ytd") {
            return getYearToDateMetrics()
        } else if query.contains("trend") || query.contains("over time") {
            return getTrendAnalysis()
        } else if query.contains("best") || query.contains("worst") {
            return getBestWorstPerformance()
        } else if query.contains("volatility") || query.contains("risk") {
            return getVolatilityMetrics()
        } else if query.contains("contribution") || query.contains("cash flow") {
            return getCashFlowAnalysis()
        } else if query.contains("growth") || query.contains("return") {
            return getGrowthAnalysis()
        } else {
            return getOverallSummary()
        }
    }
    
    // MARK: - Analysis Methods
    
    private func getCurrentMetrics() -> PerformanceResult {
        guard let latest = portfolioData.last else {
            return PerformanceResult.error("No current data available")
        }
        
        let data: [String: Any] = [
            "current_value": latest.marketValue,
            "market_change": latest.marketChange,
            "ytd_return_gross": latest.yearToDateRateOfReturnGross,
            "ytd_return_net": latest.yearToDateOfReturn,
            "net_arr": latest.netARR,
            "gross_arr": latest.grossARR,
            "value_date": latest.valueDate
        ]
        
        return PerformanceResult(
            success: true,
            data: data,
            message: "Current portfolio value: $\(String(format: "%.2f", latest.marketValue)) with YTD return of \(String(format: "%.2f", latest.yearToDateRateOfReturnGross * 100))%"
        )
    }
    
    private func getYearToDateMetrics() -> PerformanceResult {
        guard let latest = portfolioData.last else {
            return PerformanceResult.error("No YTD data available")
        }
        
        let data: [String: Any] = [
            "ytd_gross_return": latest.yearToDateRateOfReturnGross,
            "ytd_net_return": latest.yearToDateOfReturn,
            "ytd_gross_percent": latest.yearToDateRateOfReturnGross * 100,
            "ytd_net_percent": latest.yearToDateOfReturn * 100,
            "annualized_return_net": latest.netARR,
            "annualized_return_gross": latest.grossARR
        ]
        
        return PerformanceResult(
            success: true,
            data: data,
            message: "YTD Performance: \(String(format: "%.2f", latest.yearToDateRateOfReturnGross * 100))% gross, \(String(format: "%.2f", latest.yearToDateOfReturn * 100))% net"
        )
    }
    
    private func getTrendAnalysis() -> PerformanceResult {
        let monthlyReturns = portfolioData.map { $0.yearToDateRateOfReturnGross }
        let marketChanges = portfolioData.map { $0.marketChange }
        
        let avgReturn = monthlyReturns.reduce(0, +) / Double(monthlyReturns.count)
        let avgChange = marketChanges.reduce(0, +) / Double(marketChanges.count)
        
        let data: [String: Any] = [
            "monthly_returns": monthlyReturns,
            "market_changes": marketChanges,
            "average_return": avgReturn,
            "average_monthly_change": avgChange,
            "trend_direction": marketChanges.suffix(3).reduce(0, +) > 0 ? "positive" : "negative",
            "data_points": portfolioData.count
        ]
        
        return PerformanceResult(
            success: true,
            data: data,
            message: "Portfolio trending \(marketChanges.suffix(3).reduce(0, +) > 0 ? "upward" : "downward") with average return of \(String(format: "%.2f", avgReturn * 100))%"
        )
    }
    
    private func getBestWorstPerformance() -> PerformanceResult {
        let changes = portfolioData.map { $0.marketChange }
        let returns = portfolioData.map { $0.yearToDateRateOfReturnGross }
        
        guard let bestChange = changes.max(),
              let worstChange = changes.min(),
              let bestReturn = returns.max(),
              let worstReturn = returns.min() else {
            return PerformanceResult.error("Insufficient data for best/worst analysis")
        }
        
        let bestChangeMonth = portfolioData.first { $0.marketChange == bestChange }
        let worstChangeMonth = portfolioData.first { $0.marketChange == worstChange }
        
        let data: [String: Any] = [
            "best_monthly_change": bestChange,
            "worst_monthly_change": worstChange,
            "best_return": bestReturn,
            "worst_return": worstReturn,
            "best_month": bestChangeMonth?.valueDate ?? "Unknown",
            "worst_month": worstChangeMonth?.valueDate ?? "Unknown"
        ]
        
        return PerformanceResult(
            success: true,
            data: data,
            message: "Best month: $\(String(format: "%.2f", bestChange)) gain, Worst month: $\(String(format: "%.2f", worstChange)) change"
        )
    }
    
    private func getVolatilityMetrics() -> PerformanceResult {
        let changes = portfolioData.map { $0.marketChange }
        let returns = portfolioData.map { $0.yearToDateRateOfReturnGross }
        
        let avgChange = changes.reduce(0, +) / Double(changes.count)
        let avgReturn = returns.reduce(0, +) / Double(returns.count)
        
        let changeVariance = changes.map { pow($0 - avgChange, 2) }.reduce(0, +) / Double(changes.count)
        let returnVariance = returns.map { pow($0 - avgReturn, 2) }.reduce(0, +) / Double(returns.count)
        
        let changeStdDev = sqrt(changeVariance)
        let returnStdDev = sqrt(returnVariance)
        
        let data: [String: Any] = [
            "change_volatility": changeStdDev,
            "return_volatility": returnStdDev,
            "avg_monthly_change": avgChange,
            "avg_return": avgReturn,
            "risk_level": changeStdDev > 1000 ? "High" : changeStdDev > 500 ? "Medium" : "Low"
        ]
        
        return PerformanceResult(
            success: true,
            data: data,
            message: "Portfolio volatility: \(changeStdDev > 1000 ? "High" : changeStdDev > 500 ? "Medium" : "Low") risk with $\(String(format: "%.2f", changeStdDev)) standard deviation"
        )
    }
    
    private func getCashFlowAnalysis() -> PerformanceResult {
        let contributions = portfolioData.map { $0.contributionAndWithdraw }
        let totalContributions = contributions.reduce(0, +)
        let avgContribution = totalContributions / Double(contributions.count)
        
        let positiveContributions = contributions.filter { $0 > 0 }
        let withdrawals = contributions.filter { $0 < 0 }
        
        let data: [String: Any] = [
            "total_contributions": totalContributions,
            "average_monthly_contribution": avgContribution,
            "positive_contributions": positiveContributions.count,
            "withdrawals": withdrawals.count,
            "net_contribution": totalContributions,
            "contribution_trend": contributions.suffix(3).reduce(0, +) > 0 ? "increasing" : "decreasing"
        ]
        
        return PerformanceResult(
            success: true,
            data: data,
            message: "Net contributions: $\(String(format: "%.2f", totalContributions)) with average monthly flow of $\(String(format: "%.2f", avgContribution))"
        )
    }
    
    private func getGrowthAnalysis() -> PerformanceResult {
        guard let first = portfolioData.first,
              let last = portfolioData.last else {
            return PerformanceResult.error("Insufficient data for growth analysis")
        }
        
        let totalGrowth = last.marketValue - first.marketValue
        let totalContributions = portfolioData.map { $0.contributionAndWithdraw }.reduce(0, +)
        let organicGrowth = totalGrowth - totalContributions
        
        let timeSpan = portfolioData.count
        let monthlyGrowthRate = organicGrowth / Double(timeSpan)
        
        let data: [String: Any] = [
            "total_growth": totalGrowth,
            "organic_growth": organicGrowth,
            "contributed_growth": totalContributions,
            "monthly_growth_rate": monthlyGrowthRate,
            "starting_value": first.marketValue,
            "ending_value": last.marketValue,
            "time_period_months": timeSpan
        ]
        
        return PerformanceResult(
            success: true,
            data: data,
            message: "Portfolio grew by $\(String(format: "%.2f", totalGrowth)) total, with $\(String(format: "%.2f", organicGrowth)) organic growth"
        )
    }
    
    private func getOverallSummary() -> PerformanceResult {
        guard let latest = portfolioData.last else {
            return PerformanceResult.error("No portfolio data available")
        }
        
        let data: [String: Any] = [
            "current_value": latest.marketValue,
            "ytd_return": latest.yearToDateRateOfReturnGross,
            "recent_change": latest.marketChange,
            "net_arr": latest.netARR,
            "gross_arr": latest.grossARR,
            "summary": "Portfolio Performance Overview"
        ]
        
        return PerformanceResult(
            success: true,
            data: data,
            message: "Portfolio Overview: $\(String(format: "%.2f", latest.marketValue)) value, \(String(format: "%.2f", latest.yearToDateRateOfReturnGross * 100))% YTD return"
        )
    }
}

// MARK: - Supporting Types

struct PortfolioSnapshot {
    let clientID: String
    let marketChange: Double
    let marketValue: Double
    let valueDate: String
    let yearToDateRateOfReturnGross: Double
    let yearToDateOfReturn: Double
    let contributionAndWithdraw: Double
    let netARR: Double
    let grossARR: Double
    let indices: [String]
    
    init?(from dict: [String: Any]) {
        guard let clientID = dict["clientID"] as? String,
              let marketChange = dict["marketChange"] as? Double,
              let marketValue = dict["marketValue"] as? Double,
              let valueDate = dict["valueDate"] as? String,
              let yearToDateRateOfReturnGross = dict["yearToDateRateOfReturnGross"] as? Double,
              let yearToDateOfReturn = dict["yearToDateOfReturn"] as? Double,
              let contributionAndWithdraw = dict["contributionAndWithdraw"] as? Double,
              let netARR = dict["netARR"] as? Double,
              let grossARR = dict["grossARR"] as? Double,
              let indices = dict["indices"] as? [String] else {
            return nil
        }
        
        self.clientID = clientID
        self.marketChange = marketChange
        self.marketValue = marketValue
        self.valueDate = valueDate
        self.yearToDateRateOfReturnGross = yearToDateRateOfReturnGross
        self.yearToDateOfReturn = yearToDateOfReturn
        self.contributionAndWithdraw = contributionAndWithdraw
        self.netARR = netARR
        self.grossARR = grossARR
        self.indices = indices
    }
}

struct PerformanceResult {
    let success: Bool
    let data: [String: Any]
    let message: String
    
    static func error(_ message: String) -> PerformanceResult {
        return PerformanceResult(success: false, data: [:], message: message)
    }
}

enum PerformanceError: Error, LocalizedError {
    case missingData(String)
    case invalidFormat(String)
    case calculationError(String)
    
    var errorDescription: String? {
        switch self {
        case .missingData(let message): return "Missing data: \(message)"
        case .invalidFormat(let message): return "Invalid format: \(message)"
        case .calculationError(let message): return "Calculation error: \(message)"
        }
    }
}
