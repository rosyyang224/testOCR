import Foundation
import CoreGraphics

/// Responsible for detecting MRZ zones from OCR output
struct MRZProcessor {
    
    /// Normalizes MRZ line by removing extra spaces and padding with '<' if needed
    static func normalizeMRZLine(_ text: String) -> String {
        var cleaned = text.replacingOccurrences(of: " ", with: "")
                          .replacingOccurrences(of: "\n", with: "")
                          .trimmingCharacters(in: .whitespacesAndNewlines)

        // Replace commonly misread symbols if needed (optional future logic)

        // Pad with < if it's shorter than 44 characters (TD3 standard)
        if cleaned.count < 44 {
            cleaned += String(repeating: "<", count: 44 - cleaned.count)
        } else if cleaned.count > 44 {
            cleaned = String(cleaned.prefix(44))
        }

        return cleaned
    }

    /// Filters and returns likely MRZ lines from OCR words
    static func detectMRZLines(from words: [RecognizedWord]) -> [RecognizedWord] {
        let mrzCandidates = words.compactMap { word -> RecognizedWord? in
            let raw = word.text
            let cleaned = raw.replacingOccurrences(of: "<", with: "")
                             .replacingOccurrences(of: " ", with: "")
                             .trimmingCharacters(in: .whitespacesAndNewlines)
            
            let characterCount = raw.count
            let isLikelyMRZ = raw.contains("<") && characterCount >= 30 && characterCount <= 45
            let isUppercaseOnly = cleaned.range(of: "^[A-Z0-9]+$", options: .regularExpression) != nil

            guard isLikelyMRZ && isUppercaseOnly else { return nil }

            return RecognizedWord(text: normalizeMRZLine(raw), boundingBox: word.boundingBox)
        }

        return mrzCandidates.sorted { $0.boundingBox.minY > $1.boundingBox.minY }
    }
    
    /// Determines whether the grouped MRZ candidates form a valid MRZ block (TD3 or TD1)
    static func isLikelyMRZBlock(_ mrzLines: [RecognizedWord]) -> Bool {
        guard mrzLines.count == 2 || mrzLines.count == 3 else { return false }
        let maxY = mrzLines.map { $0.boundingBox.maxY }.max() ?? 0
        return maxY < 0.3 // bottom 30% of image
    }

    /// Full debug-enhanced detection + printing
    static func detectAndPrintMRZ(from words: [RecognizedWord]) -> [RecognizedWord]? {
        print("\nRaw OCR Results (All Observations):")
        for word in words {
            print("- \"\(word.text)\" — box: \(word.boundingBox)")
        }

        let candidates = detectMRZLines(from: words)

        print("\nMRZ Candidate Lines Detected: \(candidates.count)")
        for line in candidates {
            print("  → \(line.text)")
        }

        if candidates.count == 1 {
            print("Only one MRZ-like line found — attempting to split into two...")
            let raw = candidates[0].text
            let mid = raw.count / 2
            let firstLine = String(raw.prefix(mid))
            let secondLine = String(raw.suffix(from: raw.index(raw.startIndex, offsetBy: mid)))

            let fallback: [RecognizedWord] = [
                RecognizedWord(text: normalizeMRZLine(firstLine), boundingBox: candidates[0].boundingBox),
                RecognizedWord(text: normalizeMRZLine(secondLine), boundingBox: candidates[0].boundingBox)
            ]

            print("Split into:")
            fallback.forEach { print("  → \($0.text)") }
            return fallback
        }

        guard candidates.count >= 2 else {
            print("Not enough MRZ lines to parse.")
            return nil
        }

        print("MRZ Detected with \(candidates.count) lines.")
        return candidates
    }
}
