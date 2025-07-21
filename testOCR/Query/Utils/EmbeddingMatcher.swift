import Foundation

/// Handles semantic matching using embeddings for portfolio field filtering
class EmbeddingMatcher {
    
    // MARK: - Field Tag Configuration
    
    private static let fieldTags: [String: [String]] = [
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
    
    private static let operatorTags: [String: [String]] = [
        "greater": ["above", "over", "more than", "higher", "greater", "exceeds", "top", "largest", "biggest"],
        "less": ["below", "under", "less than", "lower", "smaller", "bottom", "smallest", "minimum"],
        "equal": ["equals", "is", "exactly", "matching", "same as", "specific"],
        "contains": ["includes", "has", "contains", "with", "featuring", "type of"],
        "positive": ["positive", "gaining", "up", "winning", "profitable", "green", "increasing"],
        "negative": ["negative", "losing", "down", "declining", "unprofitable", "red", "decreasing"]
    ]
    
    private static let valueTypeTags: [String: [String]] = [
        "equity": ["stock", "equity", "share", "common", "ordinary"],
        "bond": ["bond", "fixed income", "debt", "treasury", "corporate bond"],
        "etf": ["etf", "fund", "index", "tracker", "exchange traded"],
        "us": ["us", "usa", "america", "american", "united states", "domestic"],
        "international": ["international", "foreign", "overseas", "global", "non-us", "emerging"],
        "tech": ["technology", "tech", "software", "internet", "digital", "innovation"],
        "finance": ["financial", "bank", "insurance", "payment", "fintech"]
    ]
    
    // MARK: - Embedding-Based Matching
    
    struct FieldMatch {
        let fieldName: String
        let operator: String
        let value: String?
        let confidence: Double
    }
    
    struct QueryAnalysis {
        let fieldMatches: [FieldMatch]
        let sortPreference: String?
        let limitHint: Int?
    }
    
    /// Analyzes a natural language query and returns semantic field matches
    static func analyzeQuery(_ query: String, availableFields: [String]) -> QueryAnalysis {
        let lowercasedQuery = query.lowercased()
        let queryTokens = tokenizeQuery(lowercasedQuery)
        
        var fieldMatches: [FieldMatch] = []
        var sortPreference: String? = nil
        var limitHint: Int? = nil
        
        // Extract sorting preferences
        if queryTokens.contains(where: { ["largest", "biggest", "top", "highest"].contains($0) }) {
            sortPreference = "descending"
        } else if queryTokens.contains(where: { ["smallest", "lowest", "bottom"].contains($0) }) {
            sortPreference = "ascending"
        }
        
        // Extract limit hints
        for token in queryTokens {
            if let number = Int(token), number <= 50 {
                limitHint = number
                break
            }
        }
        if queryTokens.contains("top") || queryTokens.contains("best") {
            limitHint = limitHint ?? 10
        }
        
        // Find field matches using embedding similarity
        for field in availableFields {
            if let match = findBestFieldMatch(field: field, queryTokens: queryTokens, originalQuery: lowercasedQuery) {
                fieldMatches.append(match)
            }
        }
        
        return QueryAnalysis(
            fieldMatches: fieldMatches,
            sortPreference: sortPreference,
            limitHint: limitHint
        )
    }
    
    private static func findBestFieldMatch(field: String, queryTokens: [String], originalQuery: String) -> FieldMatch? {
        guard let fieldTagList = fieldTags[field] else { return nil }
        
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
        
        // Determine operator
        let operator = determineOperator(from: queryTokens, for: field)
        
        // Extract value if applicable
        let value = extractValue(from: originalQuery, for: field, operator: operator)
        
        return FieldMatch(
            fieldName: field,
            operator: operator,
            value: value,
            confidence: bestFieldScore
        )
    }
    
    private static func determineOperator(from tokens: [String], for field: String) -> String {
        // Check for explicit operators
        for (op, tags) in operatorTags {
            for token in tokens {
                for tag in tags {
                    if calculateSemanticSimilarity(token, tag) > 0.7 {
                        return op
                    }
                }
            }
        }
        
        // Field-specific defaults
        switch field {
        case "marketplpercentinsccy":
            if tokens.contains(where: { ["positive", "gaining", "up", "winning"].contains($0) }) {
                return "positive"
            } else if tokens.contains(where: { ["negative", "losing", "down", "declining"].contains($0) }) {
                return "negative"
            }
            return "greater"
        case "totalmarketvalue":
            return "greater"
        default:
            return "contains"
        }
    }
    
    private static func extractValue(from query: String, for field: String, operator: String) -> String? {
        let lowercased = query.lowercased()
        
        // Extract specific values based on field type
        switch field {
        case "assetclass":
            for (valueType, tags) in valueTypeTags {
                for tag in tags {
                    if lowercased.contains(tag) {
                        return valueType
                    }
                }
            }
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
    
    // MARK: - Simplified Semantic Similarity
    
    /// Calculates semantic similarity between two strings
    /// In production, this would use actual embeddings from a model
    private static func calculateSemanticSimilarity(_ word1: String, _ word2: String) -> Double {
        // Exact match
        if word1 == word2 {
            return 1.0
        }
        
        // Substring match
        if word1.contains(word2) || word2.contains(word1) {
            return 0.8
        }
        
        // Common stemming/lemmatization patterns
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
    
    // MARK: - Filter Application
    
    /// Applies embedding-matched filters to holdings data
    static func applySemanticFilters(
        to holdings: [[String: Any]], 
        using analysis: QueryAnalysis
    ) -> [[String: Any]] {
        
        var filtered = holdings
        
        // Apply each field match
        for match in analysis.fieldMatches.sorted(by: { $0.confidence > $1.confidence }) {
            filtered = applyFieldFilter(
                to: filtered, 
                field: match.fieldName, 
                operator: match.operator, 
                value: match.value
            )
        }
        
        // Apply sorting if specified
        if let sortPref = analysis.sortPreference {
            filtered = applySorting(to: filtered, preference: sortPref, fieldMatches: analysis.fieldMatches)
        }
        
        // Apply limit
        if let limit = analysis.limitHint {
            filtered = Array(filtered.prefix(limit))
        }
        
        return filtered
    }
    
    private static func applyFieldFilter(
        to holdings: [[String: Any]], 
        field: String, 
        operator: String, 
        value: String?
    ) -> [[String: Any]] {
        
        return holdings.filter { holding in
            guard let fieldValue = holding[field] else { return false }
            
            switch operator {
            case "positive":
                return (fieldValue as? Double ?? 0) > 0
            case "negative":
                return (fieldValue as? Double ?? 0) < 0
            case "greater":
                if let threshold = Double(value ?? "0") {
                    return (fieldValue as? Double ?? 0) > threshold
                }
                return true
            case "less":
                if let threshold = Double(value ?? "0") {
                    return (fieldValue as? Double ?? 0) < threshold
                }
                return true
            case "contains":
                let fieldStr = String(describing: fieldValue).lowercased()
                if let targetValue = value {
                    return matchFieldValue(fieldStr, targetValue: targetValue)
                }
                return true
            case "equal":
                let fieldStr = String(describing: fieldValue).lowercased()
                if let targetValue = value {
                    return fieldStr == targetValue.lowercased()
                }
                return true
            default:
                return true
            }
        }
    }
    
    private static func matchFieldValue(_ fieldValue: String, targetValue: String) -> String {
        // Enhanced value matching using semantic tags
        let target = targetValue.lowercased()
        
        switch target {
        case "equity", "stock":
            return fieldValue.contains("equity") || fieldValue.contains("stock")
        case "bond":
            return fieldValue.contains("bond") || fieldValue.contains("fixed")
        case "us":
            return fieldValue.contains("united states") || fieldValue.contains("usa")
        case "international":
            return !fieldValue.contains("united states") && !fieldValue.contains("usa")
        default:
            return fieldValue.contains(target)
        }
    }
    
    private static func applySorting(
        to holdings: [[String: Any]], 
        preference: String, 
        fieldMatches: [FieldMatch]
    ) -> [[String: Any]] {
        
        // Determine primary sort field from matches
        let primaryField = fieldMatches.max(by: { $0.confidence < $1.confidence })?.fieldName ?? "totalmarketvalue"
        
        return holdings.sorted { holding1, holding2 in
            guard let value1 = holding1[primaryField],
                  let value2 = holding2[primaryField] else { return false }
            
            if let num1 = value1 as? Double, let num2 = value2 as? Double {
                return preference == "descending" ? num1 > num2 : num1 < num2
            } else {
                let str1 = String(describing: value1)
                let str2 = String(describing: value2)
                return preference == "descending" ? str1 > str2 : str1 < str2
            }
        }
    }
}