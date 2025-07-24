import Foundation

enum JSONAnalysisUtils {
    
    // MARK: - JSON Parsing
    
    static func parseJSON(_ jsonString: String) throws -> [String: Any] {
        guard let data = jsonString.data(using: .utf8) else {
            throw JSONAnalysisError.invalidData("Failed to convert string to data")
        }
        
        guard let parsed = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw JSONAnalysisError.invalidFormat("Invalid JSON format")
        }
        
        return parsed
    }
    
    static func extractHoldings(from parsed: [String: Any]) throws -> [[String: Any]] {
        guard let holdings = parsed["holdings"] as? [[String: Any]] else {
            throw JSONAnalysisError.missingKey("Holdings array not found")
        }
        
        guard !holdings.isEmpty else {
            throw JSONAnalysisError.emptyData("Holdings array is empty")
        }
        
        return holdings
    }
    
    // MARK: - Type Inference
    
    enum InferredType {
        case int, double, bool, string, date, object, array, any
        
        var compactName: String {
            switch self {
            case .int: return "int"
            case .double: return "num"
            case .bool: return "bool"
            case .string: return "str"
            case .date: return "date"
            case .object: return "obj"
            case .array: return "arr"
            case .any: return "any"
            }
        }
        
        var swiftType: String {
            switch self {
            case .int: return "Int"
            case .double: return "Double"
            case .bool: return "Bool"
            case .string: return "String"
            case .date: return "Date"
            case .object: return "[String: Any]"
            case .array: return "[Any]"
            case .any: return "Any"
            }
        }
    }
    
    static func inferType(of value: Any) -> InferredType {
        switch value {
        case is Int:
            return .int
        case is Double:
            return .double
        case is Bool:
            return .bool
        case let str as String:
            if str.lowercased() == "true" || str.lowercased() == "false" {
                return .bool
            } else if str.contains("-") && str.count >= 8 {
                return .date
            } else {
                return .string
            }
        case is [String: Any]:
            return .object
        case is [Any]:
            return .array
        default:
            return .any
        }
    }
    
    // MARK: - Field Analysis
    
    static func analyzeFields(in holdings: [[String: Any]]) -> [String: FieldAnalysis] {
        guard let firstHolding = holdings.first else { return [:] }
        
        var analysis: [String: FieldAnalysis] = [:]
        
        for (key, value) in firstHolding {
            let type = inferType(of: value)
            let nlHint = NaturalLanguageProcessor.generateFieldHint(for: key)
            
            analysis[key] = FieldAnalysis(
                type: type,
                nlHint: nlHint,
                isRequired: holdings.allSatisfy { $0[key] != nil }
            )
        }
        
        return analysis
    }
    
    // MARK: - Company Mapping (Delegated to NLP)
    
    static func extractCompanyMappings(from holdings: [[String: Any]]) -> [String] {
        return NaturalLanguageProcessor.extractCompanyMappings(from: holdings)
    }
}

// MARK: - Supporting Types

struct FieldAnalysis {
    let type: JSONAnalysisUtils.InferredType
    let nlHint: String
    let isRequired: Bool
}

enum JSONAnalysisError: Error, LocalizedError {
    case invalidData(String)
    case invalidFormat(String)
    case missingKey(String)
    case emptyData(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidData(let message): return "Invalid data: \(message)"
        case .invalidFormat(let message): return "Invalid format: \(message)"
        case .missingKey(let message): return "Missing key: \(message)"
        case .emptyData(let message): return "Empty data: \(message)"
        }
    }
}

func format(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter.string(from: date)
}

func loadMockDataContainer(from jsonString: String) -> MockDataContainer? {
    let data = Data(jsonString.utf8)
    let decoder = JSONDecoder()
    do {
        return try decoder.decode(MockDataContainer.self, from: data)
    } catch {
        print("Failed to decode mock data: \(error)")
        return nil
    }
}
