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
        Schema: \(compactSchema.count) chars
        Portfolio: \(portfolioSummary.count) chars
        Total: \(fullSessionContext.count) chars
        """
    }
}
