import Foundation

enum MRZProcessor {
    static func detectAndPrintMRZ(from lines: [RecognizedWord]) -> [RecognizedWord]? {
        let candidates = MRZHeuristics.filterLikelyMRZ(lines)
        return candidates.count >= 2 ? candidates : nil
    }

    static func isLikelyMRZBlock(_ lines: [RecognizedWord]) -> Bool {
        MRZHeuristics.validateBlockStructure(lines)
    }

    static func detectMRZLines(from words: [RecognizedWord]) -> [RecognizedWord] {
        MRZHeuristics.filterLikelyMRZ(words)
    }
}
