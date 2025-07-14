import Foundation

class ContextManager {
    static let shared = ContextManager()
    
    private var cachedContext: OptimizedContext?
    private var lastAnalysisDate: Date?
    private let cacheExpirationInterval: TimeInterval = 3600 // 1 hour
    
    private init() {}
    
    // MARK: - Public API
    
    func getOptimizedContext(forceRefresh: Bool = false) -> OptimizedContext {
        let needsRefresh = forceRefresh || shouldRefreshCache()
        
        if needsRefresh {
            refreshCache()
        }
        
        return cachedContext ?? OptimizedContext(
            compactSchema: "ERROR: No context available",
            portfolioSummary: "ERROR: No portfolio data"
        )
    }
    
    func invalidateCache() {
        cachedContext = nil
        lastAnalysisDate = nil
    }
    
    // MARK: - Future Extension Point
    
    /// Placeholder for complex query support - will use SchemaGenerator later
    func getComplexQueryContext() -> String {
        // TODO: Implement with SchemaGenerator when needed
        // return SchemaGenerator.generateDynamicMappings(from: mockData)
        return "Complex queries not yet supported - use simple context for now"
    }
    
    // MARK: - Private Implementation
    
    private func refreshCache() {
        do {
            let parsed = try JSONAnalysisUtils.parseJSON(mockData)
            let holdings = try JSONAnalysisUtils.extractHoldings(from: parsed)
            
            let schemaContext = generateCompactSchema(from: holdings)
            let portfolioSummary = generatePortfolioSummary(from: holdings)
            
            cachedContext = OptimizedContext(
                compactSchema: schemaContext,
                portfolioSummary: portfolioSummary
            )
            lastAnalysisDate = Date()
            
        } catch {
            cachedContext = OptimizedContext(
                compactSchema: "ERROR: \(error.localizedDescription)",
                portfolioSummary: "ERROR: Failed to generate portfolio summary"
            )
        }
    }
    
    private func shouldRefreshCache() -> Bool {
        guard let lastAnalysis = lastAnalysisDate else { return true }
        return Date().timeIntervalSince(lastAnalysis) > cacheExpirationInterval
    }
    
    private func generateCompactSchema(from holdings: [[String: Any]]) -> String {
        let fieldAnalysis = JSONAnalysisUtils.analyzeFields(in: holdings)
        
        let fieldMappings = fieldAnalysis.map { (key, analysis) in
            let optional = analysis.isRequired ? "" : "?"
            return "\(key)(\(analysis.type.compactName)\(optional))→\(analysis.nlHint)"
        }.sorted()
        
        return "FIELDS: " + fieldMappings.joined(separator: ", ")
    }
    
    private func generatePortfolioSummary(from holdings: [[String: Any]]) -> String {
        let symbols = holdings.compactMap { $0["symbol"] as? String }
        let companies = JSONAnalysisUtils.extractCompanyMappings(from: holdings)
        let assetClasses = Set(holdings.compactMap { $0["assetclass"] as? String }).sorted()
        let regions = Set(holdings.compactMap { $0["countryregion"] as? String }).sorted()
        
        var summary = "SYMBOLS: \(symbols.joined(separator: ","))\n"
        summary += "COMPANIES: \(companies.joined(separator: ","))\n"
        summary += "ASSETS: \(assetClasses.joined(separator: ","))\n"
        summary += "REGIONS: \(regions.joined(separator: ","))"
        
        return summary
    }
}
