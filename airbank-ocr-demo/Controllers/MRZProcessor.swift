import Foundation
import CoreGraphics

/// Responsible for detecting MRZ zones from OCR output
struct MRZProcessor {
    
    /// Returns likely MRZ lines from OCR'd words (e.g., for passports/visas)
    static func detectMRZLines(from words: [RecognizedWord]) -> [RecognizedWord] {
        let mrzCandidates = words.filter { word in
            let cleaned = word.text.replacingOccurrences(of: "<", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            let characterCount = word.text.count
            let isLikelyMRZ = word.text.contains("<") && characterCount >= 30 && characterCount <= 44
            let isUppercaseOnly = cleaned.range(of: "^[A-Z0-9]+$", options: .regularExpression) != nil
            return isLikelyMRZ && isUppercaseOnly
        }

        return mrzCandidates.sorted { $0.boundingBox.minY > $1.boundingBox.minY }
    }
    
    /// Determines whether the grouped MRZ candidates are valid MRZ block (TD3 or TD1)
    static func isLikelyMRZBlock(_ mrzLines: [RecognizedWord]) -> Bool {
        guard mrzLines.count == 2 || mrzLines.count == 3 else { return false }
        let maxY = mrzLines.map { $0.boundingBox.maxY }.max() ?? 0
        return maxY < 0.3 // bottom 30% of image
    }

    /// Debug-enhanced version of MRZ detection
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
            let firstLine = String(raw.prefix(mid)).trimmingCharacters(in: .whitespaces)
            let secondLine = String(raw.suffix(from: raw.index(raw.startIndex, offsetBy: mid))).trimmingCharacters(in: .whitespaces)

            let fallback: [RecognizedWord] = [
                RecognizedWord(text: firstLine, boundingBox: candidates[0].boundingBox),
                RecognizedWord(text: secondLine, boundingBox: candidates[0].boundingBox)
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
