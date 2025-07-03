//
//  IDCardLayoutHelper.swift
//  airbank-ocr-demo
//
//  Created by Rosemary Yang on 7/2/25.
//


import Foundation
import Vision
import StringMetric

enum IDCardLayoutHelper {
    static func normalizeObservations(_ observations: [VNRecognizedTextObservation]) -> [(text: String, box: CGRect, observation: VNRecognizedTextObservation)] {
        return observations.compactMap {
            guard let text = $0.topCandidates(1).first?.string else { return nil }
            return (
                text.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(),
                $0.boundingBox,
                $0
            )
        }
    }

    static func matchKey(to text: String) -> RecognizedKeyValue.DocumentElement? {
        let keyParts = text.split(separator: "/").map { $0.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() }

        return RecognizedKeyValue.DocumentElement.allCases.first(where: { element in
            keyParts.contains(where: { part in
                element.keywords.contains(where: { keyword in
                    let score = keyword.distance(between: part)
                    return score > 0.85
                })
            })
        })
    }


    static func isLikelyKey(_ text: String) -> Bool {
        RecognizedKeyValue.DocumentElement.allKeywords.contains {
            $0.distance(between: text) > 0.88
        }
    }

    static func findBestMatch(from keyBox: CGRect, in candidates: [(text: String, box: CGRect, observation: VNRecognizedTextObservation)]) -> (text: String, box: CGRect, observation: VNRecognizedTextObservation)? {
        let filtered = candidates.filter { candidate in
            let isToRight = candidate.box.minX > keyBox.midX - 0.01
            let isBelow = candidate.box.midY < keyBox.midY - 0.01
            return isToRight || isBelow
        }

        return filtered.min {
            let d0 = euclideanDistance(from: keyBox, to: $0.box)
            let d1 = euclideanDistance(from: keyBox, to: $1.box)
            return d0 < d1
        }
    }

    static func isValidMatch(for key: String, value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)

        switch key.uppercased() {
        case "DATE OF BIRTH", "DATE OF ISSUE", "DATE OF EXPIRATION", "DATE OF EXPIRY":
            return trimmed.range(of: #"(\d{1,2}[\/\-.])?\d{1,2}[\/\-.]\d{2,4}"#, options: .regularExpression) != nil
        case "SEX":
            return trimmed.range(of: #"^(M|F|MALE|FEMALE)$"#, options: [.regularExpression, .caseInsensitive]) != nil
        case "GIVEN NAMES", "SURNAME", "NAME":
            return trimmed.range(of: #"^[A-Z]+(?: [A-Z]+)*$"#, options: .regularExpression) != nil
        default:
            return true
        }
    }

    private static func euclideanDistance(from a: CGRect, to b: CGRect) -> CGFloat {
        let dx = a.midX - b.midX
        let dy = a.midY - b.midY
        return sqrt(dx * dx + dy * dy)
    }
}
