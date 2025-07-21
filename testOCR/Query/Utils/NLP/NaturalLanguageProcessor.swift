import Foundation

/// Handles natural language processing for portfolio data fields and company mappings
/// Now uses EmbeddingMatcher for semantic field matching
class NaturalLanguageProcessor {
    
    // MARK: - Legacy Configuration (kept for fallback)
    
    private static let queryIntentPatterns: [QueryIntent: [String]] = [
        .performance: ["perform", "return", "gain", "loss", "profit", "pnl", "growth"],
        .sectorAnalysis: ["sector", "industry", "business", "segment", "vertical"],
        .geographicAnalysis: ["country", "region", "geographic", "location", "domicile"],
        .assetAllocation: ["asset", "class", "type", "category", "allocation"],
        .incomeAnalysis: ["dividend", "yield", "income", "distribution", "payout"],
        .riskAnalysis: ["risk", "volatility", "beta", "var", "deviation", "correlation"],
        .allocationAnalysis: ["weight", "allocation", "percentage", "proportion", "share"],
        .summaryAnalysis: ["total", "sum", "aggregate", "overall", "summary"]
    ]
    
    // MARK: - Enhanced Query Analysis Using EmbeddingMatcher
    
    struct SemanticQueryAnalysis {
        let fieldMatches: [SemanticFieldMatch]
        let intent: QueryIntent
        let operators: [(operator: String, confidence: Double)]
        let values: [(valueType: String, confidence: Double)]
        let sortPreference: String?
        let limitHint: Int?
        let companyNames: [String]
    }
    
    struct SemanticFieldMatch {
        let fieldName: String
        let confidence: Double
        let semanticDistance: Double
        let suggestedOperator: String?
        let suggestedValue: String?
    }
    
    /// Main entry point for semantic query analysis using EmbeddingMatcher
    static func analyzeSemanticQuery(_ query: String, availableFields: [String]) -> SemanticQueryAnalysis {
        // Use EmbeddingMatcher for core field matching
        let fieldMapping = EmbeddingMatcher.matchQueryToFields(query, availableFields: availableFields)
        
        // Get additional semantic analysis from EmbeddingMatcher
        let intentMatches = EmbeddingMatcher.matchQueryIntent(query)
        let operatorMatches = EmbeddingMatcher.matchQueryOperators(query)
        let valueMatches = EmbeddingMatcher.matchQueryValues(query)
        
        // Convert EmbeddingMatcher results to our format
        let semanticMatches = fieldMapping.matches.map { match in
            SemanticFieldMatch(
                fieldName: match.fieldName,
                confidence: match.confidence,
                semanticDistance: match.semanticDistance,
                suggestedOperator: determineBestOperator(for: match.fieldName, operators: operatorMatches),
                suggestedValue: determineBestValue(for: match.fieldName, values: valueMatches, query: query)
            )
        }
        
        // Determine intent (use EmbeddingMatcher results with fallback)
        let intent = determineIntent(from: intentMatches, query: query)
        
        // Extract additional query properties
        let queryTokens = tokenizeQuery(query.lowercased())
        let sortPreference = extractSortPreference(from: queryTokens)
        let limitHint = extractLimitHint(from: queryTokens)
        let companyNames = extractCompanyNamesFromQuery(query)
        
        return SemanticQueryAnalysis(
            fieldMatches: semanticMatches,
            intent: intent,
            operators: operatorMatches,
            values: valueMatches,
            sortPreference: sortPreference,
            limitHint: limitHint,
            companyNames: companyNames
        )
    }
    
    // MARK: - Helper Functions for EmbeddingMatcher Integration
    
    private static func determineBestOperator(for fieldName: String, operators: [(operator: String, confidence: Double)]) -> String? {
        // If we have high-confidence operator matches, use them
        if let bestOperator = operators.first, bestOperator.confidence > 0.6 {
            return bestOperator.operator
        }
        
        // Field-specific defaults based on semantics
        switch fieldName {
        case "marketplpercentinsccy", "marketplinsccy", "marketplinbccy":
            // Performance fields - check for positive/negative in operators
            if operators.contains(where: { $0.operator == "positive" && $0.confidence > 0.4 }) {
                return "positive"
            } else if operators.contains(where: { $0.operator == "negative" && $0.confidence > 0.4 }) {
                return "negative"
            }
            return "greater"
            
        case "totalmarketvalue", "marketvalueinbccy", "totalmarketvaluesccy":
            return "greater"
            
        case "assetclass", "securitytype", "countryregion":
            return "contains"
            
        default:
            return operators.first?.operator ?? "contains"
        }
    }
    
    private static func determineBestValue(for fieldName: String, values: [(valueType: String, confidence: Double)], query: String) -> String? {
        // Field-specific value extraction
        switch fieldName {
        case "assetclass", "securitytype":
            // Look for asset type matches
            return values.first(where: { ["equity", "bond", "etf", "cash"].contains($0.valueType) })?.valueType
            
        case "countryregion":
            // Look for geographic matches
            return values.first(where: { ["united_states", "international", "europe", "asia"].contains($0.valueType) })?.valueType
            
        case "symbol":
            // Extract ticker symbols from query
            return extractTickerSymbol(from: query)
            
        default:
            return values.first?.valueType
        }
    }
    
    private static func determineIntent(from intentMatches: [(intent: String, confidence: Double)], query: String) -> QueryIntent {
        // Use EmbeddingMatcher results first
        if let bestIntent = intentMatches.first, bestIntent.confidence > 0.4 {
            switch bestIntent.intent {
            case "performance": return .performance
            case "value": return .summaryAnalysis
            case "geography": return .geographicAnalysis
            case "asset_type": return .assetAllocation
            case "yield": return .incomeAnalysis
            default: break
            }
        }
        
        // Fallback to legacy pattern matching
        return identifyQueryIntentLegacy(from: query)
    }
    
    // MARK: - Field Hint Generation (Now EmbeddingMatcher-Powered)
    
    static func generateFieldHint(for fieldName: String) -> String {
        // Use EmbeddingMatcher to find the best semantic category for this field
        let dummyQuery = fieldName // Use field name as query to find its semantic category
        let intentMatches = EmbeddingMatcher.matchQueryIntent(dummyQuery)
        
        if let bestIntent = intentMatches.first, bestIntent.confidence > 0.3 {
            return bestIntent.intent
        }
        
        // Fallback mapping based on field name patterns
        let fieldLower = fieldName.lowercased()
        if fieldLower.contains("symbol") { return "tickers" }
        if fieldLower.contains("market") && fieldLower.contains("value") { return "position_size" }
        if fieldLower.contains("pl") || fieldLower.contains("performance") { return "performance" }
        if fieldLower.contains("country") || fieldLower.contains("region") { return "geography" }
        if fieldLower.contains("asset") || fieldLower.contains("class") { return "asset_type" }
        
        return "general"
    }
    
    // MARK: - Company Symbol Processing
    
    static func extractCompanyMappings(from holdings: [[String: Any]]) -> [String] {
        var mappings: [String] = []
        
        for holding in holdings {
            guard let symbol = holding["symbol"] as? String else { continue }
            
            // Look for explicit company name in the data
            let potentialNameFields = ["name", "company", "companyname", "issuer", "description", "longname", "fullname"]
            
            for field in potentialNameFields {
                if let companyName = holding[field] as? String, !companyName.isEmpty {
                    let cleanedName = cleanCompanyName(companyName)
                    mappings.append("\(cleanedName)=\(symbol)")
                    break
                }
            }
        }
        
        return mappings.uniqued()
    }
    
    private static func cleanCompanyName(_ name: String) -> String {
        var cleaned = name
        
        let corporateSuffixes = ["Inc.", "Inc", "Corp.", "Corp", "LLC", "Ltd.", "Ltd", "Co.", "Co",
                                "Company", "Corporation", "Limited", "Incorporated"]
        
        for suffix in corporateSuffixes {
            cleaned = cleaned.replacingOccurrences(of: " \(suffix)", with: "", options: .caseInsensitive)
        }
        
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Enhanced Query Processing
    
    static func identifyQueryIntent(from query: String) -> QueryIntent {
        // Use EmbeddingMatcher for intent identification
        let intentMatches = EmbeddingMatcher.matchQueryIntent(query)
        
        if let bestIntent = intentMatches.first, bestIntent.confidence > 0.4 {
            switch bestIntent.intent {
            case "performance": return .performance
            case "value": return .summaryAnalysis
            case "geography": return .geographicAnalysis
            case "asset_type": return .assetAllocation
            case "yield": return .incomeAnalysis
            case "pricing": return .summaryAnalysis
            case "currency": return .geographicAnalysis
            case "timing": return .general
            case "identification": return .general
            default: return .general
            }
        }
        
        // Fallback to legacy method
        return identifyQueryIntentLegacy(from: query)
    }
    
    private static func identifyQueryIntentLegacy(from query: String) -> QueryIntent {
        let normalizedQuery = query.lowercased()
        let queryTokens = tokenizeQuery(normalizedQuery)
        
        var intentScores: [(QueryIntent, Double)] = []
        
        for (intent, patterns) in queryIntentPatterns {
            var score = 0.0
            
            for token in queryTokens {
                for pattern in patterns {
                    if token.contains(pattern) || pattern.contains(token) {
                        score += 1.0
                    }
                }
            }
            
            intentScores.append((intent, score))
        }
        
        let bestIntent = intentScores.max { $0.1 < $1.1 }
        return bestIntent?.1 ?? 0.0 > 0.5 ? bestIntent!.0 : .general
    }
    
    static func suggestRelevantFields(for intent: QueryIntent) -> [String] {
        // Map intent to semantic category and use EmbeddingMatcher
        let intentString = mapIntentToString(intent)
        let fieldMapping = EmbeddingMatcher.matchQueryToFields(intentString, availableFields: Array(FieldTagsConfig.fieldSemanticTags.keys))
        
        return fieldMapping.matches.filter { $0.confidence > 0.3 }.map { $0.fieldName }
    }
    
    private static func mapIntentToString(_ intent: QueryIntent) -> String {
        switch intent {
        case .performance: return "performance return gain loss"
        case .sectorAnalysis: return "sector industry business"
        case .geographicAnalysis: return "country region geography"
        case .assetAllocation: return "asset class type allocation"
        case .incomeAnalysis: return "dividend yield income"
        case .riskAnalysis: return "risk volatility"
        case .allocationAnalysis: return "allocation weight percentage"
        case .summaryAnalysis: return "total value summary"
        case .general: return "general"
        }
    }
    
    // MARK: - Company Name Extraction
    
    static func extractCompanyNamesFromQuery(_ query: String) -> [String] {
        let words = query.components(separatedBy: .whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .filter { !$0.isEmpty && $0.count > 1 }
        
        var potentialCompanyNames: [String] = []
        
        // Look for capitalized words that might be company names
        for word in words {
            if word.first?.isUppercase == true {
                let commonWords = ["I", "The", "A", "An", "This", "That", "Show", "Tell", "What", "How", "When", "Where"]
                if !commonWords.contains(word) {
                    potentialCompanyNames.append(word)
                }
            }
        }
        
        // Look for multi-word company names
        var i = 0
        while i < words.count - 1 {
            let currentWord = words[i]
            let nextWord = words[i + 1]
            
            if currentWord.first?.isUppercase == true && nextWord.first?.isUppercase == true {
                potentialCompanyNames.append("\(currentWord) \(nextWord)")
                i += 2
            } else {
                i += 1
            }
        }
        
        return potentialCompanyNames.uniqued()
    }
    
    static func prepareCompanyResolutionContext(from query: String, availableSymbols: [String]) -> String {
        let companyNames = extractCompanyNamesFromQuery(query)
        
        if companyNames.isEmpty {
            return "No company names detected in query."
        }
        
        var context = "Available symbols in portfolio: \(availableSymbols.joined(separator: ", "))\n"
        context += "Company names mentioned in query: \(companyNames.joined(separator: ", "))\n"
        context += "Please resolve company names to their stock symbols if they match any available symbols."
        
        return context
    }
    
    // MARK: - Utility Functions
    
    private static func extractSortPreference(from tokens: [String]) -> String? {
        if tokens.contains(where: { ["largest", "biggest", "top", "highest"].contains($0) }) {
            return "descending"
        } else if tokens.contains(where: { ["smallest", "lowest", "bottom"].contains($0) }) {
            return "ascending"
        }
        return nil
    }
    
    private static func extractLimitHint(from tokens: [String]) -> Int? {
        for token in tokens {
            if let number = Int(token), number <= 50 {
                return number
            }
        }
        if tokens.contains("top") || tokens.contains("best") {
            return 10
        }
        return nil
    }
    
    private static func extractTickerSymbol(from query: String) -> String? {
        let words = query.components(separatedBy: .whitespacesAndNewlines)
        for word in words {
            if word.allSatisfy({ $0.isUppercase || $0.isNumber || $0 == "." }) && word.count >= 1 && word.count <= 10 {
                return word
            }
        }
        return nil
    }
    
    private static func tokenizeQuery(_ query: String) -> [String] {
        var characterSet = CharacterSet.whitespacesAndNewlines
        characterSet.formUnion(.punctuationCharacters)
        
        return query.components(separatedBy: characterSet)
            .filter { !$0.isEmpty && $0.count > 1 }
            .map { $0.lowercased() }
    }
    
    // MARK: - Configuration Management
    
    static func addFieldPattern(hint: String, patterns: [String]) {
        guard !hint.isEmpty && !patterns.isEmpty else { return }
        print("Would add pattern: \(hint) -> \(patterns)")
    }
}

// MARK: - Supporting Types

enum QueryIntent {
    case performance
    case sectorAnalysis
    case geographicAnalysis
    case assetAllocation
    case incomeAnalysis
    case riskAnalysis
    case allocationAnalysis
    case summaryAnalysis
    case general
}

// MARK: - Extensions

extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
