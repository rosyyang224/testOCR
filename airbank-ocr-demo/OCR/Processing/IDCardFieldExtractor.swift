import Foundation
import Vision

struct IDCardFieldExtractor {
    static func extractKeyValuePairs(from lines: [(text: String, box: CGRect, observation: VNRecognizedTextObservation)]) -> [RecognizedKeyValue] {
        var results: [RecognizedKeyValue] = []

        for (keyText, keyBox, keyObs) in lines {
            guard let matchedElement = IDCardLayoutHelper.matchKey(to: keyText) else { continue }

            let candidates = lines.filter { candidate in
                candidate.observation != keyObs &&
                !IDCardLayoutHelper.isLikelyKey(candidate.text)
            }

            let bestMatch = IDCardLayoutHelper.findBestMatch(from: keyBox, in: candidates)

            if let match = bestMatch,
               IDCardLayoutHelper.isValidMatch(for: matchedElement.rawValue, value: match.text) {
                results.append(RecognizedKeyValue(
                    key: matchedElement.rawValue,
                    value: match.text,
                    keyTextObservation: keyObs,
                    valueTextObservation: match.observation
                ))
            }
        }

        return results
    }
}
