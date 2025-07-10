import Foundation

struct SectionedChunkGroup {
    let key: String
    let chunks: [String]
}

enum JSONChunker {
    static func chunkJSON(_ raw: String, maxChunkSize: Int = 3500) throws -> [SectionedChunkGroup] {
        guard let topLevel = try JSONSerialization.jsonObject(with: Data(raw.utf8)) as? [String: Any] else {
            throw NSError(domain: "Invalid JSON", code: 1)
        }

        var sectionSizes: [String: Int] = [:]
        var sectionArrays: [String: [Any]] = [:]

        // Estimate total size per section
        for (key, value) in topLevel {
            if let array = value as? [Any] {
                let wrapped = [key: array]
                if let data = try? JSONSerialization.data(withJSONObject: wrapped, options: []),
                   let string = String(data: data, encoding: .utf8) {
                    sectionSizes[key] = string.count
                    sectionArrays[key] = array
                }
            }
        }

        var result: [SectionedChunkGroup] = []

        for (key, array) in sectionArrays {
            let totalSize = sectionSizes[key] ?? 0
            let estimatedChunks = max(1, Int(ceil(Double(totalSize) / Double(maxChunkSize))))
            let itemsPerChunk = max(1, array.count / estimatedChunks)

            print("New top-level section: \(key)")
            print("Estimated total size: \(totalSize), target chunks: \(estimatedChunks), items per chunk: \(itemsPerChunk)")

            let chunks = evenlyChunkJSONArray(key: key, array: array, itemsPerChunk: itemsPerChunk)
            for (i, c) in chunks.enumerated() {
                print("[\(key) - Chunk \(i+1)] Prompt size: \(c.count)")
            }
            result.append(SectionedChunkGroup(key: key, chunks: chunks))
        }

        // Handle non-array sections
        for (key, value) in topLevel where sectionArrays[key] == nil {
            let chunkObj: [String: Any] = [key: value]
            if let data = try? JSONSerialization.data(withJSONObject: chunkObj, options: .prettyPrinted),
               let chunkString = String(data: data, encoding: .utf8) {
                print("[\(key) - Chunk 1] Prompt size: \(chunkString.count)")
                result.append(SectionedChunkGroup(key: key, chunks: [chunkString]))
            }
        }

        return result
    }

    private static func evenlyChunkJSONArray(key: String, array: [Any], itemsPerChunk: Int) -> [String] {
        var chunks: [String] = []

        let totalItems = array.count
        let chunkCount = Int(ceil(Double(totalItems) / Double(itemsPerChunk)))

        for i in 0..<chunkCount {
            let start = i * itemsPerChunk
            let end = min(start + itemsPerChunk, totalItems)
            let chunkItems = Array(array[start..<end])

            if let batchData = try? JSONSerialization.data(withJSONObject: [key: chunkItems], options: .prettyPrinted),
               let batchString = String(data: batchData, encoding: .utf8) {
                chunks.append(batchString)
            }
        }

        return chunks
    }
}
