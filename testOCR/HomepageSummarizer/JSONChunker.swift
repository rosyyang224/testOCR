import Foundation

struct SectionedChunkGroup {
    let key: String
    let chunks: [String]
}

enum JSONChunker {
    /// Returns grouped chunks by top-level JSON key (e.g., "portfolio_value", "transactions", etc.)
    static func chunkJSON(_ raw: String, maxChunkSize: Int = 1500) throws -> [SectionedChunkGroup] {
        guard let topLevel = try JSONSerialization.jsonObject(with: Data(raw.utf8)) as? [String: Any] else {
            throw NSError(domain: "Invalid JSON", code: 1)
        }

        var result: [SectionedChunkGroup] = []
        print("Starting grouped chunking...")

        for (key, value) in topLevel {
            if let array = value as? [Any] {
                print("Processing array key: \(key) → \(array.count) items")
                let chunks = chunkJSONArrayBySize(key: key, array: array, maxChunkSize: maxChunkSize)
                print("   \(chunks.count) chunks created for key: \(key)")
                result.append(SectionedChunkGroup(key: key, chunks: chunks))
            } else {
                // Scalar values
                let chunkObj: [String: Any] = [key: value]
                if let data = try? JSONSerialization.data(withJSONObject: chunkObj, options: .prettyPrinted),
                   let chunkString = String(data: data, encoding: .utf8) {
                    print("Single value key: \(key), size: \(chunkString.count)")
                    result.append(SectionedChunkGroup(key: key, chunks: [chunkString]))
                }
            }
        }

        print("Done. Sectioned chunks ready: \(result.count)")
        return result
    }

    private static func chunkJSONArrayBySize(key: String, array: [Any], maxChunkSize: Int) -> [String] {
        var chunks: [String] = []
        var currentBatch: [Any] = []
        var currentSize = 0

        for item in array {
            let wrapped = [key: [item]]
            guard let data = try? JSONSerialization.data(withJSONObject: wrapped, options: .prettyPrinted),
                  let itemString = String(data: data, encoding: .utf8) else { continue }

            let itemSize = itemString.count

            if currentSize + itemSize > maxChunkSize, !currentBatch.isEmpty {
                if let batchData = try? JSONSerialization.data(withJSONObject: [key: currentBatch], options: .prettyPrinted),
                   let batchString = String(data: batchData, encoding: .utf8) {
                    chunks.append(batchString)
                }
                currentBatch = [item]
                currentSize = itemSize
            } else {
                currentBatch.append(item)
                currentSize += itemSize
            }
        }

        if !currentBatch.isEmpty {
            if let batchData = try? JSONSerialization.data(withJSONObject: [key: currentBatch], options: .prettyPrinted),
               let batchString = String(data: batchData, encoding: .utf8) {
                chunks.append(batchString)
            }
        }

        return chunks
    }
}
