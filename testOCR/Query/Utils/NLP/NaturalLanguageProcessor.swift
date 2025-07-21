import Foundation

/// Handles natural language processing for portfolio data fields and company mappings
class NaturalLanguageProcessor {
    
    // MARK: - Configuration with Embedding Tags
    
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
    
    private static let fieldEmbeddingTags: [String: [String]] = [
        "symbol": ["ticker", "stock", "symbol", "code", "instrument", "security"],
        "assetclass": ["asset", "type", "category", "class", "equity", "bond", "stock", "fixed income", "etf", "fund"],
        "countryregion": ["country", "region", "geography", "location", "domestic", "international", "us", "america", "china", "europe"],
        "marketplpercentinsccy": ["performance", "return", "gain", "loss", "profit", "pnl", "change", "growth", "decline"],
        "totalmarketvalue": ["value", "worth", "size", "amount", "market cap", "position", "holding", "investment"],
        "sector": ["industry", "sector", "business", "technology", "healthcare", "finance", "energy"],
        "weight": ["allocation", "percentage", "weight", "proportion", "share", "portion"],
        "dividend": ["income", "yield", "payout", "distribution", "dividend"],
        "risk": ["volatility", "risk", "beta", "variance", "deviation", "stability"],
        "maturity": ["duration", "term", "maturity", "expiry", "time", "period"]
    ]
    
    private static let operatorEmbeddingTags: [String: [String]] = [
        "greater": ["above", "over", "more than", "higher", "greater", "exceeds", "top", "largest", "biggest"],
        "less": ["below", "under", "less than", "lower", "smaller", "bottom", "smallest", "minimum"],
        "equal": ["equals", "is", "exactly", "matching", "same as", "specific"],
        "contains": ["includes", "has", "contains", "with", "featuring", "type of"],
        "positive": ["positive", "gaining", "up", "winning", "profitable", "green", "increasing"],
        "negative": ["negative", "losing", "down", "declining", "unprofitable", "red", "decreasing"]
    ]
    
    private static let valueTypeEmbeddingTags: [String: [String]] = [
        "equity": ["stock", "equity", "share", "common", "ordinary"],
        "bond": ["bond", "fixed income", "debt", "treasury", "corporate bond"],
        "etf": ["etf", "fund", "index", "tracker", "exchange traded"],
        "us": ["us", "usa", "america", "american", "united states", "domestic"],
        "international": ["international", "foreign", "overseas", "global", "non-us", "emerging"],
        "tech": ["technology", "tech", "software", "internet", "digital", "innovation"],
        "finance": ["financial", "bank", "insurance", "payment", "fintech"]
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
    
    // MARK: - Embedding-Based Query Analysis
    
    struct SemanticQueryAnalysis {
        let fieldMatches: [FieldMatch]
        let intent: QueryIntent
        let sortPreference: String?
        let limitHint: Int?
        let companyNames: [String]
    }
    
    struct FieldMatch {
        let fieldName: String
        let operator: String
        let value: String?
        let confidence: Double
    }
    
    /// Main entry point for semantic query analysis using embeddings
    static func analyzeSemanticQuery(_ query: String, availableFields: [String]) -> SemanticQueryAnalysis {
        let lowercasedQuery = query.lowercased()
        let queryTokens = tokenizeQuery(lowercasedQuery)
        
        // Analyze using embedding-based matching
        let fieldMatches = findSemanticFieldMatches(queryTokens: queryTokens, availableFields: availableFields, originalQuery: lowercasedQuery)
        let intent = identifyQueryIntent(from: query)
        let sortPreference = extractSortPreference(from: queryTokens)
        let limitHint = extractLimitHint(from: queryTokens)
        let companyNames = extractCompanyNamesFromQuery(query)
        
        return SemanticQueryAnalysis(
            fieldMatches: fieldMatches,
            intent: intent,
            sortPreference: sortPreference,
            limitHint: limitHint,
            companyNames: companyNames
        )
    }
    
    private static func findSemanticFieldMatches(queryTokens: [String], availableFields: [String], originalQuery: String) -> [FieldMatch] {
        var fieldMatches: [FieldMatch] = []
        
        for field in availableFields {
            if let match = findBestFieldMatch(field: field, queryTokens: queryTokens, originalQuery: originalQuery) {
                fieldMatches.append(match)
            }
        }
        
        return fieldMatches.sorted { $0.confidence > $1.confidence }
    }
    
    private static func findBestFieldMatch(field: String, queryTokens: [String], originalQuery: String) -> FieldMatch? {
        guard let fieldTagList = fieldEmbeddingTags[field] else { return nil }
        
        // Calculate semantic similarity between query tokens and field tags
        var bestFieldScore = 0.0
        for token in queryTokens {
            for tag in fieldTagList {
                let similarity = calculateSemanticSimilarity(token, tag)
                bestFieldScore = max(bestFieldScore, similarity)
            }
        }
        
        // Require minimum confidence threshold
        guard bestFieldScore > 0.3 else { return nil }
        
        // Determine operator using embedding matching
        let operator = determineSemanticOperator(from: queryTokens, for: field)
        
        // Extract value if applicable
        let value = extractSemanticValue(from: originalQuery, for: field, operator: operator)
        
        return FieldMatch(
            fieldName: field,
            operator: operator,
            value: value,
            confidence: bestFieldScore
        )
    }
    
    private static func determineSemanticOperator(from tokens: [String], for field: String) -> String {
        var bestOperator = "contains"
        var bestScore = 0.0
        
        // Check for explicit operators using embedding similarity
        for (op, tags) in operatorEmbeddingTags {
            for token in tokens {
                for tag in tags {
                    let similarity = calculateSemanticSimilarity(token, tag)
                    if similarity > bestScore {
                        bestScore = similarity
                        bestOperator = op
                    }
                }
            }
        }
        
        // Field-specific defaults if no strong operator match
        if bestScore < 0.6 {
            switch field {
            case "marketplpercentinsccy":
                if tokens.contains(where: { token in
                    ["positive", "gaining", "up", "winning"].contains { calculateSemanticSimilarity(token, $0) > 0.7 }
                }) {
                    return "positive"
                } else if tokens.contains(where: { token in
                    ["negative", "losing", "down", "declining"].contains { calculateSemanticSimilarity(token, $0) > 0.7 }
                }) {
                    return "negative"
                }
                return "greater"
            case "totalmarketvalue":
                return "greater"
            default:
                return "contains"
            }
        }
        
        return bestOperator
    }
    
    private static func extractSemanticValue(from query: String, for field: String, operator: String) -> String? {
        let lowercased = query.lowercased()
        
        // Extract specific values based on field type using embedding matching
        switch field {
        case "assetclass":
            var bestValue: String?
            var bestScore = 0.0
            
            for (valueType, tags) in valueTypeEmbeddingTags {
                for tag in tags {
                    if lowercased.contains(tag) {
                        let similarity = calculateSemanticSimilarity(lowercased, tag)
                        if similarity > bestScore {
                            bestScore = similarity
                            bestValue = valueType
                        }
                    }
                }
            }
            return bestValue
            
        case "countryregion":
            if lowercased.contains("us") || lowercased.contains("america") {
                return "us"
            } else if lowercased.contains("international") || lowercased.contains("foreign") {
                return "international"
            }
            
        case "symbol":
            // Extract potential ticker symbols (uppercase letters)
            let words = query.components(separatedBy: .whitespacesAndNewlines)
            for word in words {
                if word.allSatisfy({ $0.isUppercase || $0.isNumber || $0 == "." }) && word.count >= 1 && word.count <= 10 {
                    return word
                }
            }
            
        default:
            break
        }
        
        return nil
    }
    
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
    
    // MARK: - Semantic Similarity Engine
    
    /// Calculates semantic similarity between two strings using embedding-like approach
    private static func calculateSemanticSimilarity(_ word1: String, _ word2: String) -> Double {
        // Exact match
        if word1 == word2 {
            return 1.0
        }
        
        // Substring match
        if word1.contains(word2) || word2.contains(word1) {
            return 0.8
        }
        
        // Stemming-based similarity
        let stems1 = generateStems(word1)
        let stems2 = generateStems(word2)
        
        for stem1 in stems1 {
            for stem2 in stems2 {
                if stem1 == stem2 {
                    return 0.6
                }
            }
        }
        
        // Character-level similarity (Jaccard)
        let set1 = Set(word1)
        let set2 = Set(word2)
        let intersection = set1.intersection(set2)
        let union = set1.union(set2)
        
        let jaccardSimilarity = Double(intersection.count) / Double(union.count)
        
        return jaccardSimilarity > 0.4 ? jaccardSimilarity * 0.5 : 0.0
    }
    
    private static func generateStems(_ word: String) -> [String] {
        var stems = [word]
        
        // Simple stemming rules
        if word.hasSuffix("ing") {
            stems.append(String(word.dropLast(3)))
        }
        if word.hasSuffix("ed") {
            stems.append(String(word.dropLast(2)))
        }
        if word.hasSuffix("s") && word.count > 3 {
            stems.append(String(word.dropLast(1)))
        }
        if word.hasSuffix("ly") {
            stems.append(String(word.dropLast(2)))
        }
        
        return stems
    }
    
    private static func tokenizeQuery(_ query: String) -> [String] {
        return query.components(separatedBy: .whitespacesAndPunctuationCharacters)
            .filter { !$0.isEmpty && $0.count > 1 }
            .map { $0.lowercased() }
    }
    
    // MARK: - Enhanced Field Hint Generation (Now Embedding-Aware)
    
    /// Generates natural language hints using embedding-based pattern matching
    static func generateFieldHint(for fieldName: String) -> String {
        let normalizedField = fieldName.lowercased()
        
        // First try embedding-based matching
        if let embeddingTags = fieldEmbeddingTags[normalizedField] {
            return determineHintFromEmbeddingTags(embeddingTags)
        }
        
        // Fallback to pattern matching
        let bestMatch = fieldPatterns.max { first, second in
            let firstScore = calculateSemanticScore(normalizedField, patterns: first.value)
            let secondScore = calculateSemanticScore(normalizedField, patterns: second.value)
            return firstScore < secondScore
        }
        
        return bestMatch?.key ?? "general"
    }
    
    private static func determineHintFromEmbeddingTags(_ tags: [String]) -> String {
        // Analyze semantic clusters in tags to determine best hint
        if tags.contains(where: { ["performance", "return", "gain", "loss"].contains($0) }) {
            return "performance"
        } else if tags.contains(where: { ["symbol", "ticker", "code"].contains($0) }) {
            return "tickers"
        } else if tags.contains(where: { ["value", "amount", "position"].contains($0) }) {
            return "position_size"
        } else if tags.contains(where: { ["country", "region", "geography"].contains($0) }) {
            return "geography"
        } else if tags.contains(where: { ["asset", "type", "class"].contains($0) }) {
            return "asset_type"
        }
        return "general"
    }
    
    /// Enhanced pattern scoring using semantic similarity
    private static func calculateSemanticScore(_ field: String, patterns: [String]) -> Double {
        var score = 0.0
        let fieldWords = field.components(separatedBy: CharacterSet.alphanumerics.inverted)
        
        for pattern in patterns {
            let patternWords = pattern.components(separatedBy: CharacterSet.alphanumerics.inverted)
            
            // Use semantic similarity instead of exact matching
            for fieldWord in fieldWords {
                for patternWord in patternWords {
                    if !fieldWord.isEmpty && !patternWord.isEmpty {
                        let similarity = calculateSemanticSimilarity(fieldWord, patternWord)
                        score += similarity * 2.0 // Weight semantic matches
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
    
    // MARK: - Enhanced Query Processing (Now Embedding-Powered)
    
    /// Processes user queries using enhanced embedding-based intent recognition
    static func identifyQueryIntent(from query: String) -> QueryIntent {
        let normalizedQuery = query.lowercased()
        let queryTokens = tokenizeQuery(normalizedQuery)
        
        // Calculate semantic scores for each intent using embedding-like approach
        var intentScores: [(QueryIntent, Double)] = []
        
        for (intent, patterns) in queryIntentPatterns {
            var score = 0.0
            
            for token in queryTokens {
                for pattern in patterns {
                    let similarity = calculateSemanticSimilarity(token, pattern)
                    score += similarity
                }
            }
            
            intentScores.append((intent, score))
        }
        
        // Return the intent with the highest score, or general if no good matches
        let bestIntent = intentScores.max { $0.1 < $1.1 }
        return bestIntent?.1 ?? 0.0 > 1.0 ? bestIntent!.0 : .general
    }
    
    /// Enhanced field suggestions using semantic analysis
    static func suggestRelevantFields(for intent: QueryIntent) -> [String] {
        let baseFields = queryIntentPatterns[intent] ?? []
        
        // Use embedding tags to find semantically related fields
        return fieldEmbeddingTags.compactMap { fieldName, tags in
            let relevantToIntent = tags.contains { tag in
                baseFields.contains { baseField in
                    calculateSemanticSimilarity(tag, baseField) > 0.5
                }
            }
            return relevantToIntent ? fieldName : nil
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
