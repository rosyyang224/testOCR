import Foundation

struct OptimizedContext {
    let compactSchema: String
    let portfolioSummary: String
    
    var fullSessionContext: String {
        return """
        SCHEMA: \(compactSchema)
        
        PORTFOLIO: \(portfolioSummary)
        """
    }
    
    var minimalContext: String {
        return "Use established field mappings from session start."
    }
    
    var debugInfo: String {
        return """
        Context Debug Info:
        - Schema: \(compactSchema.count) chars
        - Portfolio: \(portfolioSummary.count) chars
        - Full context: \(fullSessionContext.count) chars
        - Minimal context: \(minimalContext.count) chars
        """
    }
    
    var toolInstructions: String {
        return """
        \(fullSessionContext)
        
        TOOL USAGE GUIDE:
        • Use SYMBOLS for exact ticker lookups (AAPL, TSLA, 9988.HK)
        • Use COMPANIES for natural language queries (Apple→AAPL, Tesla→TSLA)
        • Filter by ASSETS for asset class queries (Fixed Income, Equity)
        • Filter by REGIONS for geographic queries (United States, Hong Kong)
        
        QUERY EXAMPLES:
        • "Apple stock" → Use COMPANIES mapping: Apple=AAPL
        • "US positions" → Filter by countryregion = "United States"
        • "Bonds" → Filter by assetclass = "Fixed Income"
        • "Performance" → Sort by marketplpercentinsccy field
        """
    }
}

