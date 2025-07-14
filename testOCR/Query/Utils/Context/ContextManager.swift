import Foundation

class ContextManager {
    static let shared = ContextManager()
    
    private var cachedSchemaContext: String?
    private var cachedPortfolioSummary: String?
    private var lastAnalysisDate: Date?
    private let cacheExpirationInterval: TimeInterval = 3600
    
    private init() {}
    
    func getOptimizedContext(forceRefresh: Bool = false) -> OptimizedContext {
        let needsRefresh = forceRefresh ||
                          cachedSchemaContext == nil ||
                          shouldRefreshCache()
        
        if needsRefresh {
            refreshCache()
        }
        
        return OptimizedContext(
            compactSchema: cachedSchemaContext ?? "",
            portfolioSummary: cachedPortfolioSummary ?? ""
        )
    }
    
    func invalidateCache() {
        cachedSchemaContext = nil
        cachedPortfolioSummary = nil
        lastAnalysisDate = nil
    }
    
    private func refreshCache() {
        cachedSchemaContext = generateCompactSchema()
        cachedPortfolioSummary = generatePortfolioSummary()
        lastAnalysisDate = Date()
        print("Context cache refreshed")
    }
    
    private func shouldRefreshCache() -> Bool {
        guard let lastAnalysis = lastAnalysisDate else { return true }
        return Date().timeIntervalSince(lastAnalysis) > cacheExpirationInterval
    }
    
    private func generateCompactSchema() -> String {
        guard let jsonData = mockData.data(using: .utf8),
              let parsed = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let holdings = parsed["holdings"] as? [[String: Any]],
              let firstHolding = holdings.first
        else {
            return "SCHEMA_ERROR"
        }
        
        var compact = "FIELDS: "
        let fieldMappings = firstHolding.map { (key, value) -> String in
            let type = getCompactType(value)
            let nlHint = getNLHint(for: key)
            return "\(key)(\(type))→\(nlHint)"
        }
        compact += fieldMappings.joined(separator: ", ")
        return compact
    }
    
    private func generatePortfolioSummary() -> String {
        guard let jsonData = mockData.data(using: .utf8),
              let parsed = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let holdings = parsed["holdings"] as? [[String: Any]]
        else {
            return "PORTFOLIO_ERROR"
        }
        
        let symbols = holdings.compactMap { $0["symbol"] as? String }
        let companies = extractCompanyMappings(from: holdings)
        let assetClasses = Set(holdings.compactMap { $0["assetclass"] as? String })
        let regions = Set(holdings.compactMap { $0["countryregion"] as? String })
        
        var summary = "SYMBOLS: \(symbols.joined(separator: ","))\n"
        summary += "COMPANIES: \(companies.joined(separator: ","))\n"
        summary += "ASSETS: \(assetClasses.joined(separator: ","))\n"
        summary += "REGIONS: \(regions.joined(separator: ","))"
        
        return summary
    }
    
    private func extractCompanyMappings(from holdings: [[String: Any]]) -> [String] {
        return holdings.compactMap { holding in
            guard let symbol = holding["symbol"] as? String else { return nil }
            let companyName = getCompanyName(for: symbol)
            return companyName != symbol ? "\(companyName)=\(symbol)" : nil
        }
    }
    
    private func getCompanyName(for symbol: String) -> String {
        switch symbol {
        case "AAPL": return "Apple"
        case "TSLA": return "Tesla"
        case "9988.HK": return "Alibaba"
        case let s where s.contains("US912"): return "TreasuryBond"
        default: return symbol
        }
    }
    
    private func getCompactType(_ value: Any) -> String {
        if value is Double || value is Int { return "num" }
        if value is String {
            let str = value as! String
            if str.lowercased() == "true" || str.lowercased() == "false" { return "bool" }
            if str.contains("-") && str.count >= 8 { return "date" }
            return "str"
        }
        return "obj"
    }
    
    private func getNLHint(for fieldName: String) -> String {
        let field = fieldName.lowercased()
        if field.contains("symbol") { return "tickers" }
        if field.contains("market") && field.contains("value") { return "position_size" }
        if field.contains("performance") || field.contains("pl") { return "performance" }
        if field.contains("country") || field.contains("region") { return "geography" }
        if field.contains("asset") && field.contains("class") { return "asset_type" }
        return "general"
    }
}
