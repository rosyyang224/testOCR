// Query/QueryRouter.swift
import Foundation

enum QueryRouter {
    
    enum QueryType {
        case simple      // "Show me Apple", "What's my Tesla position?"
        case complex     // "Analyze performance over 10 years" (future)
        case unknown
        
        var contextMethod: ContextMethod {
            switch self {
            case .simple: return .optimized
            case .complex: return .dynamic  // Will use SchemaGenerator
            case .unknown: return .optimized // Default to simple
            }
        }
    }
    
    enum ContextMethod {
        case optimized   // Use ContextManager.getOptimizedContext()
        case dynamic     // Use ContextManager.getComplexQueryContext() (future)
    }
    
    static func analyzeQuery(_ query: String) -> QueryType {
        let lowercased = query.lowercased()
        
        // Complex query patterns (for future implementation)
        let complexPatterns = [
            "analyze.*over.*years",
            "performance.*last.*\\d+.*years",
            "compare.*to.*benchmark",
            "historical.*analysis",
            "trend.*analysis",
            "correlation",
            "regression"
        ]
        
        for pattern in complexPatterns {
            if lowercased.range(of: pattern, options: .regularExpression) != nil {
                return .complex
            }
        }
        
        // Simple query patterns (current implementation)
        let simplePatterns = [
            "show",
            "what",
            "do i have",
            "my.*position",
            "holdings",
            "stocks",
            "bonds"
        ]
        
        for pattern in simplePatterns {
            if lowercased.range(of: pattern, options: .regularExpression) != nil {
                return .simple
            }
        }
        
        // Default to simple for now
        return .simple
    }
    
    static func getContext(for query: String) -> String {
        let queryType = analyzeQuery(query)
        
        switch queryType.contextMethod {
        case .optimized:
            let context = ContextManager.shared.getOptimizedContext()
            return context.toolInstructions
            
        case .dynamic:
            // Future: Will use SchemaGenerator for complex analysis
            let fallbackContext = ContextManager.shared.getOptimizedContext()
            return fallbackContext.toolInstructions + "\n\nNOTE: Complex analysis not yet implemented"
        }
    }
    
    // Debugging helper
    static func debugQuery(_ query: String) -> String {
        let type = analyzeQuery(query)
        return """
        Query: "\(query)"
        Detected type: \(type)
        Context method: \(type.contextMethod)
        """
    }
}