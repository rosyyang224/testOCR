import Foundation
import FoundationModels

// MARK: - Public Schema Generator

enum SchemaGenerator {
    static func generateSchema(from json: String) throws -> GenerationSchema {
        guard let data = json.data(using: .utf8),
              let topLevel = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            throw SchemaGenerationError.invalidJSON("Invalid JSON format")
        }

        var rootBuilder = SchemaBuilder(name: "MockData")
        var dependencies: [DynamicGenerationSchema] = []

        for (key, value) in topLevel {
            if let array = value as? [[String: Any]] {
                let (elementSchema, elementDependencies) = try inferSchema(from: array, name: key.capitalized)
                rootBuilder.addArrayProperty(name: key, elementType: .object(key.capitalized))
                dependencies.append(elementSchema)
                dependencies.append(contentsOf: elementDependencies)
            }
        }

        let rootSchema = rootBuilder.root
        return try GenerationSchema(root: rootSchema, dependencies: dependencies)
    }

    static func generateSwiftStructs(from json: String) throws -> String {
        let numberTypeMap = try extractNumberTypes(from: json)
        guard let data = json.data(using: .utf8),
              let topLevel = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]) as? [String: [Any]] else {
            throw SchemaGenerationError.invalidJSON("Invalid JSON or top-level format")
        }

        var output = ""
        var nestedStructs: [String: String] = [:]

        for (typeName, records) in topLevel {
            let (structDef, nested) = try generateStruct(named: typeName.capitalized, from: records, numberMap: numberTypeMap)
            output += structDef + "\n"
            nestedStructs.merge(nested) { $1 }
        }

        for (_, nestedCode) in nestedStructs {
            output += nestedCode + "\n"
        }

        return output
    }
}

// MARK: - Type Inference

enum InferredType {
    case int, double, bool, string, date, object(String), arrayOfObject(String), any

    var swiftType: String {
        switch self {
        case .int: return "Int"
        case .double: return "Double"
        case .bool: return "Bool"
        case .string: return "String"
        case .date: return "Date"
        case .object(let name): return name
        case .arrayOfObject(let name): return "[\(name)]"
        case .any: return "Any"
        }
    }

    func createSchema(name: String? = nil) -> DynamicGenerationSchema {
        switch self {
        case .int: return DynamicGenerationSchema(type: Int.self)
        case .double: return DynamicGenerationSchema(type: Double.self)
        case .bool: return DynamicGenerationSchema(type: Bool.self)
        case .string, .date: return DynamicGenerationSchema(type: String.self)
        case .object(let typeName):
            // For object types, create a named schema that will be resolved by dependencies
            return DynamicGenerationSchema(name: typeName, properties: [])
        case .arrayOfObject(let typeName):
            // For arrays, we need to create a schema for the array itself
            // The element type schema will be handled separately in dependencies
            return DynamicGenerationSchema(type: [String].self) // Fallback to string array
        case .any: return DynamicGenerationSchema(type: String.self)
        }
    }
}

// MARK: - Schema Inference Helpers

private func infer(_ value: Any, fallbackName: String) -> InferredType {
    switch value {
    case is Int: return .int
    case is Double: return .double
    case is Bool: return .bool
    case let s as String:
        return s.range(of: #"^\d{4}-\d{2}-\d{2}"#, options: .regularExpression) != nil ? .date : .string
    case let arr as [Any]:
        return arr.allSatisfy({ $0 is [String: Any] }) ? .arrayOfObject(fallbackName + "Item") : .any
    case is [String: Any]:
        return .object(fallbackName)
    default:
        return .any
    }
}

private func inferSchema(from array: [[String: Any]], name: String) throws -> (DynamicGenerationSchema, [DynamicGenerationSchema]) {
    var builder = SchemaBuilder(name: name)
    var dependencies: [DynamicGenerationSchema] = []

    let allKeys = array.flatMap { $0.keys }.reduce(into: Set<String>()) { $0.insert($1) }

    var props: [(String, InferredType)] = []

    for key in allKeys {
        for dict in array {
            if let value = dict[key] {
                let inferredType = infer(value, fallbackName: name + key.capitalized)
                props.append((key, inferredType))
                
                // Add nested object schemas as dependencies
                switch inferredType {
                case .object(let objName):
                    if let nestedDict = value as? [String: Any] {
                        let nestedSchema = try createNestedSchema(from: nestedDict, name: objName)
                        dependencies.append(nestedSchema)
                    }
                case .arrayOfObject(let objName):
                    if let nestedArray = value as? [[String: Any]] {
                        let (nestedSchema, nestedDeps) = try inferSchema(from: nestedArray, name: objName)
                        dependencies.append(nestedSchema)
                        dependencies.append(contentsOf: nestedDeps)
                    }
                default:
                    break
                }
                break
            }
        }
    }

    builder.addProperties(props)
    return (builder.root, dependencies)
}

private func createNestedSchema(from dict: [String: Any], name: String) throws -> DynamicGenerationSchema {
    var properties: [DynamicGenerationSchema.Property] = []
    
    for (key, value) in dict {
        let inferredType = infer(value, fallbackName: name + key.capitalized)
        let property = DynamicGenerationSchema.Property(name: key, schema: inferredType.createSchema())
        properties.append(property)
    }
    
    return DynamicGenerationSchema(name: name, properties: properties)
}

// MARK: - Swift Struct Generator

private func generateStruct(named typeName: String, from records: [Any], numberMap: [String: Bool]) throws -> (String, [String: String]) {
    var fieldTypes: [String: Set<String>] = [:]
    var fieldPresence: [String: Int] = [:]
    var fieldHasNull: Set<String> = []
    var nestedStructs: [String: String] = [:]
    let totalRecords = records.count

    for record in records.compactMap({ $0 as? [String: Any] }) {
        for (key, value) in record {
            fieldPresence[key, default: 0] += 1
            if value is NSNull {
                fieldHasNull.insert(key)
                continue
            }
            if let type = inferSwiftType(value, key: key, numberMap: numberMap) {
                fieldTypes[key, default: []].insert(type)
            }

            if let dict = value as? [String: Any] {
                let nestedName = "\(typeName)\(key.capitalized)"
                let (nestedDef, nestedInner) = try generateStruct(named: nestedName, from: [dict], numberMap: numberMap)
                nestedStructs[nestedName] = nestedDef
                nestedStructs.merge(nestedInner) { $1 }
            } else if let array = value as? [Any], array.allSatisfy({ $0 is [String: Any] }) {
                let nestedName = "\(typeName)\(key.capitalized)Item"
                let (nestedDef, nestedInner) = try generateStruct(named: nestedName, from: array, numberMap: numberMap)
                nestedStructs[nestedName] = nestedDef
                nestedStructs.merge(nestedInner) { $1 }
            }
        }
    }

    var structCode = "struct \(typeName): Codable {\n"
    for key in fieldTypes.keys.sorted() {
        let types = fieldTypes[key] ?? []
        let isOptional = fieldHasNull.contains(key) || fieldPresence[key] != totalRecords
        let finalType = resolveFinalType(types, typeName: typeName, key: key)
        structCode += "    let \(key): \(finalType)\(isOptional ? "?" : "")\n"
    }
    structCode += "}\n"
    return (structCode, nestedStructs)
}

private func resolveFinalType(_ types: Set<String>, typeName: String, key: String) -> String {
    if types == Set(["Int", "Double"]) { return "Double" }
    guard types.count == 1, let type = types.first else { return "Any" }
    switch type {
    case "Date": return "Date"
    case "Nested": return "\(typeName)\(key.capitalized)"
    case "Array<Nested>": return "[\(typeName)\(key.capitalized)Item]"
    default: return type
    }
}

private func inferSwiftType(_ value: Any, key: String, numberMap: [String: Bool]) -> String? {
    switch value {
    case is NSNull: return nil
    case let s as String:
        return s.range(of: #"^\d{4}-\d{2}-\d{2}"#, options: .regularExpression) != nil ? "Date" : "String"
    case is Bool:
        return numberMap[key] == true ? "Double" : "Bool"
    case let number as NSNumber:
        return (numberMap[key] == true || CFNumberIsFloatType(number)) ? "Double" : "Int"
    case is [String]: return "[String]"
    case let array as [Any]: return array.allSatisfy({ $0 is [String: Any] }) ? "Array<Nested>" : "[Any]"
    case is [String: Any]: return "Nested"
    default: return "Any"
    }
}

private func extractNumberTypes(from json: String) throws -> [String: Bool] {
    var map: [String: Bool] = [:]
    let pattern = #""([^\"]+)"\s*:\s*(-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)"#
    let regex = try NSRegularExpression(pattern: pattern)

    for match in regex.matches(in: json, range: NSRange(json.startIndex..., in: json)) {
        guard let fieldRange = Range(match.range(at: 1), in: json),
              let numberRange = Range(match.range(at: 2), in: json) else { continue }
        let field = String(json[fieldRange])
        let number = String(json[numberRange])
        map[field] = number.contains(".") || number == "0.00" || number == "1.00"
    }
    return map
}

// MARK: - Schema Builder

private struct SchemaBuilder {
    let name: String
    var properties: [DynamicGenerationSchema.Property] = []

    init(name: String) { self.name = name }

    mutating func addProperties(_ props: [(String, InferredType)]) {
        for (name, type) in props {
            let property = DynamicGenerationSchema.Property(name: name, schema: type.createSchema())
            properties.append(property)
        }
    }

    mutating func addArrayProperty(name: String, elementType: InferredType) {
        let property = DynamicGenerationSchema.Property(name: name, schema: elementType.createSchema())
        properties.append(property)
    }

    var root: DynamicGenerationSchema {
        DynamicGenerationSchema(name: name, properties: properties)
    }
}

// MARK: - Errors

enum SchemaGenerationError: Error, LocalizedError {
    case invalidJSON(String)

    var errorDescription: String? {
        switch self {
        case .invalidJSON(let message): return message
        }
    }
}
