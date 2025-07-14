//// Schema/SchemaGenerator.swift
//import Foundation
//import FoundationModels
//
//enum SchemaGenerator {
//    
//    // MARK: - Public API
//    
//    static func generateSchema(from json: String) throws -> GenerationSchema {
//        let parsed = try JSONAnalysisUtils.parseJSON(json)
//        
//        var rootBuilder = SchemaBuilder(name: "MockData")
//        var dependencies: [DynamicGenerationSchema] = []
//        
//        for (key, value) in parsed {
//            if let array = value as? [[String: Any]] {
//                let (elementSchema, elementDependencies) = try buildSchemaFromArray(array, name: key.capitalized)
//                rootBuilder.addArrayProperty(name: key, elementType: .object(key.capitalized))
//                dependencies.append(elementSchema)
//                dependencies.append(contentsOf: elementDependencies)
//            }
//        }
//        
//        return try GenerationSchema(root: rootBuilder.root, dependencies: dependencies)
//    }
//    
//    static func generateSwiftStructs(from json: String) throws -> String {
//        let parsed = try JSONAnalysisUtils.parseJSON(json)
//        let numberTypeMap = try extractNumberTypes(from: json)
//        
//        guard let topLevel = parsed as? [String: [Any]] else {
//            throw SchemaGenerationError.invalidJSON("Invalid top-level format")
//        }
//        
//        var output = ""
//        var nestedStructs: [String: String] = [:]
//        
//        for (typeName, records) in topLevel {
//            let (structDef, nested) = try generateStruct(
//                named: typeName.capitalized,
//                from: records,
//                numberMap: numberTypeMap
//            )
//            output += structDef + "\n"
//            nestedStructs.merge(nested) { $1 }
//        }
//        
//        for (_, nestedCode) in nestedStructs {
//            output += nestedCode + "\n"
//        }
//        
//        return output
//    }
//    
//    // MARK: - Private Implementation
//    
//    private static func buildSchemaFromArray(_ array: [[String: Any]], name: String) throws -> (DynamicGenerationSchema, [DynamicGenerationSchema]) {
//        let fieldAnalysis = JSONAnalysisUtils.analyzeFields(in: array)
//        
//        var builder = SchemaBuilder(name: name)
//        var dependencies: [DynamicGenerationSchema] = []
//        
//        for (key, analysis) in fieldAnalysis {
//            let property = DynamicGenerationSchema.Property(
//                name: key,
//                schema: analysis.type.createGenerationSchema()
//            )
//            builder.addProperty(property)
//            
//            // Handle nested dependencies
//            if case .object = analysis.type {
//                let nestedDependencies = try extractNestedDependencies(from: array, key: key, name: name)
//                dependencies.append(contentsOf: nestedDependencies)
//            }
//        }
//        
//        return (builder.root, dependencies)
//    }
//    
//    private static func extractNestedDependencies(from array: [[String: Any]], key: String, name: String) throws -> [DynamicGenerationSchema] {
//        // Extract nested object schemas - simplified version
//        // Full implementation would recursively analyze nested structures
//        return []
//    }
//    
//    private static func generateStruct(named typeName: String, from records: [Any], numberMap: [String: Bool]) throws -> (String, [String: String]) {
//        // Use existing implementation but with shared utilities where possible
//        // This part stays mostly the same as it's specific to Swift struct generation
//        
//        var fieldTypes: [String: Set<String>] = [:]
//        var fieldPresence: [String: Int] = [:]
//        var fieldHasNull: Set<String> = []
//        var nestedStructs: [String: String] = [:]
//        let totalRecords = records.count
//        
//        for record in records.compactMap({ $0 as? [String: Any] }) {
//            for (key, value) in record {
//                fieldPresence[key, default: 0] += 1
//                if value is NSNull {
//                    fieldHasNull.insert(key)
//                    continue
//                }
//                
//                let inferredType = JSONAnalysisUtils.inferType(of: value)
//                let swiftType = inferredType.swiftType
//                fieldTypes[key, default: []].insert(swiftType)
//                
//                // Handle nested structures
//                if case .object = inferredType {
//                    let nestedName = "\(typeName)\(key.capitalized)"
//                    if let dict = value as? [String: Any] {
//                        let (nestedDef, nestedInner) = try generateStruct(named: nestedName, from: [dict], numberMap: numberMap)
//                        nestedStructs[nestedName] = nestedDef
//                        nestedStructs.merge(nestedInner) { $1 }
//                    }
//                }
//            }
//        }
//        
//        var structCode = "struct \(typeName): Codable {\n"
//        for key in fieldTypes.keys.sorted() {
//            let types = fieldTypes[key] ?? []
//            let isOptional = fieldHasNull.contains(key) || fieldPresence[key] != totalRecords
//            let finalType = resolveFinalType(types, typeName: typeName, key: key)
//            structCode += "    let \(key): \(finalType)\(isOptional ? "?" : "")\n"
//        }
//        structCode += "}\n"
//        
//        return (structCode, nestedStructs)
//    }
//    
//    private static func resolveFinalType(_ types: Set<String>, typeName: String, key: String) -> String {
//        if types == Set(["Int", "Double"]) { return "Double" }
//        guard types.count == 1, let type = types.first else { return "Any" }
//        
//        switch type {
//        case "Date": return "Date"
//        case "[String: Any]": return "\(typeName)\(key.capitalized)"
//        case "[Any]": return "[\(typeName)\(key.capitalized)Item]"
//        default: return type
//        }
//    }
//    
//    private static func extractNumberTypes(from json: String) throws -> [String: Bool] {
//        var map: [String: Bool] = [:]
//        let pattern = #""([^\"]+)"\s*:\s*(-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)"#
//        let regex = try NSRegularExpression(pattern: pattern)
//        
//        for match in regex.matches(in: json, range: NSRange(json.startIndex..., in: json)) {
//            guard let fieldRange = Range(match.range(at: 1), in: json),
//                  let numberRange = Range(match.range(at: 2), in: json) else { continue }
//            let field = String(json[fieldRange])
//            let number = String(json[numberRange])
//            map[field] = number.contains(".") || number == "0.00" || number == "1.00"
//        }
//        return map
//    }
//}
//
//// MARK: - Extensions
//
//extension JSONAnalysisUtils.InferredType {
//    func createGenerationSchema() -> DynamicGenerationSchema {
//        switch self {
//        case .int: return DynamicGenerationSchema(type: Int.self)
//        case .double: return DynamicGenerationSchema(type: Double.self)
//        case .bool: return DynamicGenerationSchema(type: Bool.self)
//        case .string, .date: return DynamicGenerationSchema(type: String.self)
//        case .object: return DynamicGenerationSchema(type: [String: Any].self)
//        case .array: return DynamicGenerationSchema(type: [Any].self)
//        case .any: return DynamicGenerationSchema(type: String.self)
//        }
//    }
//}
//
//// MARK: - Supporting Types
//
//private struct SchemaBuilder {
//    let name: String
//    var properties: [DynamicGenerationSchema.Property] = []
//    
//    init(name: String) {
//        self.name = name
//    }
//    
//    mutating func addProperty(_ property: DynamicGenerationSchema.Property) {
//        properties.append(property)
//    }
//    
//    mutating func addArrayProperty(name: String, elementType: JSONAnalysisUtils.InferredType) {
//        let property = DynamicGenerationSchema.Property(
//            name: name,
//            schema: elementType.createGenerationSchema()
//        )
//        properties.append(property)
//    }
//    
//    var root: DynamicGenerationSchema {
//        DynamicGenerationSchema(name: name, properties: properties)
//    }
//}
//
//enum SchemaGenerationError: Error, LocalizedError {
//    case invalidJSON(String)
//    
//    var errorDescription: String? {
//        switch self {
//        case .invalidJSON(let message): return message
//        }
//    }
//}
