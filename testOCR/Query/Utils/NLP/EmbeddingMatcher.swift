import Foundation
import NaturalLanguage

/// Focused semantic field matcher using Apple's NLEmbedding
class EmbeddingMatcher {
    
    // MARK: - Core Embedding Models
    
    private static var sentenceEmbedding: NLEmbedding? = {
        return NLEmbedding.sentenceEmbedding(for: .english)
    }()
    
    private static var wordEmbedding: NLEmbedding? = {
        return NLEmbedding.wordEmbedding(for: .english)
    }()
    
    // MARK: - Semantic Field Matching
    
    struct FieldMatch {
        let fieldName: String
        let confidence: Double
        let semanticDistance: Double
    }
    
    struct QueryFieldMapping {
        let matches: [FieldMatch]
        let bestMatch: FieldMatch?
        let queryTokens: [String]
    }
    
    /// Main function: semantically matches user query tokens to portfolio field names
    static func matchQueryToFields(_ query: String, availableFields: [String]) -> QueryFieldMapping {
        let queryTokens = tokenizeQuery(query)
        var fieldMatches: [FieldMatch] = []
        
        for field in availableFields {
            if let match = calculateFieldMatch(queryTokens: queryTokens, fieldName: field) {
                fieldMatches.append(match)
            }
        }
        
        // Sort by confidence (higher is better)
        fieldMatches.sort { $0.confidence > $1.confidence }
        
        return QueryFieldMapping(
            matches: fieldMatches,
            bestMatch: fieldMatches.first,
            queryTokens: queryTokens
        )
    }
    
    /// Calculates semantic similarity between query tokens and a specific field's tags
    private static func calculateFieldMatch(queryTokens: [String], fieldName: String) -> FieldMatch? {
        guard let fieldTags = FieldTagsConfig.fieldSemanticTags[fieldName] else {
            return nil
        }
        
        var maxSimilarity = 0.0
        var totalSimilarity = 0.0
        var matchCount = 0
        
        // Compare each query token against each field tag using embeddings
        for queryToken in queryTokens {
            for fieldTag in fieldTags {
                let similarity = calculateSemanticSimilarity(queryToken, fieldTag)
                
                if similarity > 0.3 { // Only count meaningful similarities
                    totalSimilarity += similarity
                    matchCount += 1
                    maxSimilarity = max(maxSimilarity, similarity)
                }
            }
        }
        
        // Require at least one meaningful match
        guard matchCount > 0 else { return nil }
        
        // Calculate confidence: blend of max similarity and average similarity
        let avgSimilarity = totalSimilarity / Double(matchCount)
        let confidence = (maxSimilarity * 0.7) + (avgSimilarity * 0.3)
        
        // Only return matches above threshold
        guard confidence > 0.4 else { return nil }
        
        return FieldMatch(
            fieldName: fieldName,
            confidence: confidence,
            semanticDistance: 1.0 - maxSimilarity
        )
    }
    
    /// Uses Apple's NLEmbedding to calculate semantic similarity between two strings
    private static func calculateSemanticSimilarity(_ text1: String, _ text2: String) -> Double {
        // Try sentence embedding first for better context
        if let sentenceEmb = sentenceEmbedding {
            if let embedding1 = sentenceEmb.vector(for: text1),
               let embedding2 = sentenceEmb.vector(for: text2) {
                return cosineSimilarity(embedding1, embedding2)
            }
        }
        
        // Fallback to word embedding
        if let wordEmb = wordEmbedding {
            if let embedding1 = wordEmb.vector(for: text1),
               let embedding2 = wordEmb.vector(for: text2) {
                return cosineSimilarity(embedding1, embedding2)
            }
        }
        
        // Final fallback to string similarity
        return fallbackStringSimilarity(text1, text2)
    }
    
    /// Calculates cosine similarity between two embedding vectors
    private static func cosineSimilarity(_ vector1: [Double], _ vector2: [Double]) -> Double {
        guard vector1.count == vector2.count else { return 0.0 }
        
        let dotProduct = zip(vector1, vector2).map(*).reduce(0, +)
        let magnitude1 = sqrt(vector1.map { $0 * $0 }.reduce(0, +))
        let magnitude2 = sqrt(vector2.map { $0 * $0 }.reduce(0, +))
        
        guard magnitude1 > 0 && magnitude2 > 0 else { return 0.0 }
        
        return dotProduct / (magnitude1 * magnitude2)
    }
    
    /// Fallback string similarity when embeddings are not available
    private static func fallbackStringSimilarity(_ text1: String, _ text2: String) -> Double {
        let str1 = text1.lowercased()
        let str2 = text2.lowercased()
        
        // Exact match
        if str1 == str2 { return 1.0 }
        
        // Substring match
        if str1.contains(str2) || str2.contains(str1) { return 0.8 }
        
        // Stemming match
        let stems1 = generateStems(str1)
        let stems2 = generateStems(str2)
        
        for stem1 in stems1 {
            for stem2 in stems2 {
                if stem1 == stem2 { return 0.6 }
            }
        }
        
        // Character overlap (Jaccard)
        let set1 = Set(str1)
        let set2 = Set(str2)
        let intersection = set1.intersection(set2)
        let union = set1.union(set2)
        
        let jaccard = Double(intersection.count) / Double(union.count)
        return jaccard > 0.4 ? jaccard * 0.5 : 0.0
    }
    
    // MARK: - Additional Semantic Matching Helpers
    
    /// Matches query intent to semantic categories
    static func matchQueryIntent(_ query: String) -> [(intent: String, confidence: Double)] {
        let queryTokens = tokenizeQuery(query)
        var intentMatches: [(String, Double)] = []
        
        for (intent, tags) in FieldTagsConfig.queryIntentTags {
            var maxSimilarity = 0.0
            
            for token in queryTokens {
                for tag in tags {
                    let similarity = calculateSemanticSimilarity(token, tag)
                    maxSimilarity = max(maxSimilarity, similarity)
                }
            }
            
            if maxSimilarity > 0.3 {
                intentMatches.append((intent, maxSimilarity))
            }
        }
        
        return intentMatches.sorted { $0.1 > $1.1 }
    }
    
    /// Matches query values to semantic value types
    static func matchQueryValues(_ query: String) -> [(valueType: String, confidence: Double)] {
        let queryTokens = tokenizeQuery(query)
        var valueMatches: [(String, Double)] = []
        
        for (valueType, tags) in FieldTagsConfig.valueTypeTags {
            var maxSimilarity = 0.0
            
            for token in queryTokens {
                for tag in tags {
                    let similarity = calculateSemanticSimilarity(token, tag)
                    maxSimilarity = max(maxSimilarity, similarity)
                }
            }
            
            if maxSimilarity > 0.4 {
                valueMatches.append((valueType, maxSimilarity))
            }
        }
        
        return valueMatches.sorted { $0.1 > $1.1 }
    }
    
    /// Matches query operators semantically
    static func matchQueryOperators(_ query: String) -> [(operator: String, confidence: Double)] {
        let queryTokens = tokenizeQuery(query)
        var operatorMatches: [(String, Double)] = []
        
        for (operatorType, tags) in FieldTagsConfig.operatorTags {
            var maxSimilarity = 0.0
            
            for token in queryTokens {
                for tag in tags {
                    let similarity = calculateSemanticSimilarity(token, tag)
                    maxSimilarity = max(maxSimilarity, similarity)
                }
            }
            
            if maxSimilarity > 0.5 {
                operatorMatches.append((operatorType, maxSimilarity))
            }
        }
        
        return operatorMatches.sorted { $0.1 > $1.1 }
    }
    
    // MARK: - Utility Functions
    
    private static func tokenizeQuery(_ query: String) -> [String] {
        var characterSet = CharacterSet.whitespacesAndNewlines
        characterSet.formUnion(.punctuationCharacters)
        
        return query.components(separatedBy: characterSet)
            .filter { !$0.isEmpty && $0.count > 1 }
            .map { $0.lowercased() }
    }
    
    private static func generateStems(_ word: String) -> [String] {
        var stems = [word]
        
        if word.hasSuffix("ing") && word.count > 4 {
            stems.append(String(word.dropLast(3)))
        }
        if word.hasSuffix("ed") && word.count > 3 {
            stems.append(String(word.dropLast(2)))
        }
        if word.hasSuffix("s") && word.count > 3 {
            stems.append(String(word.dropLast(1)))
        }
        if word.hasSuffix("ly") && word.count > 3 {
            stems.append(String(word.dropLast(2)))
        }
        
        return stems
    }
}
