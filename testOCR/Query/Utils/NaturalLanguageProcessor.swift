import Foundation

/// Handles natural language processing for portfolio data fields and company mappings
class NaturalLanguageProcessor {
    
    // MARK: - Configuration
    
    private static let fieldPatterns: [String: [String]] = [
        "tickers": ["symbol", "ticker", "code", "instrument"],
        "position_size": ["market", "value", "amount", "size", "position"],
        "performance": ["performance", "pl", "return", "gain", "loss", "profit", "pnl"],
        "geography": ["country", "region", "location", "domicile", "geographic"],
        "asset_type": ["asset", "class", "type", "category", "classification"],
        "industry": ["sector", "industry", "business", "segment", "vertical"],
        "portfolio_weight": ["weight", "allocation", "percent", "proportion", "share"],
        "pricing": ["price", "cost", "value", "rate", "quote", "nav"],
        "holdings_amount": ["quantity", "shares", "units", "count", "volume"],
        "income": ["dividend", "yield", "income", "distribution", "payout"],
        "timing": ["date", "time", "period", "expiry", "maturity", "duration"],
        "currency": ["currency", "ccy", "fx", "denomination"],
        "quality_metrics": ["rating", "score", "grade", "quality", "rank"],
        "risk_metrics": ["risk", "volatility", "beta", "var", "deviation", "correlation"]
    ]
    
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
    
    // MARK: - Dynamic Field Hint Generation
    
    /// Generates natural language hints using pattern matching
    static func generateFieldHint(for fieldName: String) -> String {
        let normalizedField = fieldName.lowercased()
        
        // Find the best matching pattern
        let bestMatch = fieldPatterns.max { first, second in
            let firstScore = calculatePatternScore(normalizedField, patterns: first.value)
            let secondScore = calculatePatternScore(normalizedField, patterns: second.value)
            return firstScore < secondScore
        }
        
        return bestMatch?.key ?? "general"
    }
    
    /// Calculates how well a field matches a set of patterns
    private static func calculatePatternScore(_ field: String, patterns: [String]) -> Double {
        var score = 0.0
        let fieldWords = field.components(separatedBy: CharacterSet.alphanumerics.inverted)
        
        for pattern in patterns {
            let patternWords = pattern.components(separatedBy: CharacterSet.alphanumerics.inverted)
            
            // Exact match gets highest score
            if field == pattern {
                score += 10.0
            }
            // Substring match gets medium score
            else if field.contains(pattern) || pattern.contains(field) {
                score += 5.0
            }
            // Word-level matches get lower score
            else {
                for fieldWord in fieldWords {
                    for patternWord in patternWords {
                        if fieldWord == patternWord && !fieldWord.isEmpty {
                            score += 2.0
                        } else if fieldWord.contains(patternWord) || patternWord.contains(fieldWord) {
                            score += 1.0
                        }
                    }
                }
            }
        }
        
        return score
    }
    
    // MARK: - Company Symbol Processing
    
    /// Creates display-friendly company-symbol mappings from portfolio holdings
    /// Foundation models already know company names → symbols, so we just format what's in the portfolio
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
        
        return mappings.uniqued() // Remove duplicates if any
    }
    
    /// Cleans company names for display
    private static func cleanCompanyName(_ name: String) -> String {
        var cleaned = name
        
        // Remove common corporate suffixes for cleaner display
        let corporateSuffixes = ["Inc.", "Inc", "Corp.", "Corp", "LLC", "Ltd.", "Ltd", "Co.", "Co", 
                                "Company", "Corporation", "Limited", "Incorporated"]
        
        for suffix in corporateSuffixes {
            cleaned = cleaned.replacingOccurrences(of: " \(suffix)", with: "", options: .caseInsensitive)
        }
        
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Query Processing for Foundation Models
    
    /// Processes user queries to identify portfolio-related intent using pattern matching
    static func identifyQueryIntent(from query: String) -> QueryIntent {
        let normalizedQuery = query.lowercased()
        
        // Calculate scores for each intent
        let intentScores = queryIntentPatterns.map { intent, patterns in
            let score = calculatePatternScore(normalizedQuery, patterns: patterns)
            return (intent, score)
        }
        
        // Return the intent with the highest score, or general if no good matches
        let bestIntent = intentScores.max { $0.1 < $1.1 }
        return bestIntent?.1 ?? 0.0 > 1.0 ? bestIntent!.0 : .general
    }
    
    /// Suggests field mappings based on query intent
    static func suggestRelevantFields(for intent: QueryIntent) -> [String] {
        let baseFields = queryIntentPatterns[intent] ?? []
        
        // Expand patterns to include related field names
        return fieldPatterns.compactMap { hint, patterns in
            let relevantToIntent = patterns.contains { pattern in
                baseFields.contains { baseField in
                    pattern.contains(baseField) || baseField.contains(pattern)
                }
            }
            return relevantToIntent ? hint : nil
        }
    }
    
    /// Extracts potential company names from user queries for foundation model resolution
    /// Returns company names that a foundation model can resolve to symbols
    static func extractCompanyNamesFromQuery(_ query: String) -> [String] {
        let words = query.components(separatedBy: .whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .filter { !$0.isEmpty && $0.count > 1 }
        
        var potentialCompanyNames: [String] = []
        
        // Look for capitalized words that might be company names
        for word in words {
            if word.first?.isUppercase == true {
                // Skip common words that are capitalized but not companies
                let commonWords = ["I", "The", "A", "An", "This", "That", "Show", "Tell", "What", "How", "When", "Where"]
                if !commonWords.contains(word) {
                    potentialCompanyNames.append(word)
                }
            }
        }
        
        // Look for multi-word company names (consecutive capitalized words)
        var i = 0
        while i < words.count - 1 {
            let currentWord = words[i]
            let nextWord = words[i + 1]
            
            if currentWord.first?.isUppercase == true && nextWord.first?.isUppercase == true {
                potentialCompanyNames.append("\(currentWord) \(nextWord)")
                i += 2 // Skip next word since we've combined it
            } else {
                i += 1
            }
        }
        
        return potentialCompanyNames.uniqued()
    }
    
    /// Prepares context for foundation model queries about company-symbol resolution
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
    
    // MARK: - Configuration Management
    
    /// Allows dynamic addition of new field patterns
    static func addFieldPattern(hint: String, patterns: [String]) {
        guard !hint.isEmpty && !patterns.isEmpty else { return }
        // In a real implementation, this would modify the configuration
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