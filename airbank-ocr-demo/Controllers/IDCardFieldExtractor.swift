//
//  IDCardFieldExtractor.swift
//  airbank-ocr-demo
//
//  Created by Rosemary Yang on 7/1/25.
//  Copyright © 2025 Marek Přidal. All rights reserved.
//


import Foundation
import Vision
import StringMetric

/// Extracts key-value fields from ID card OCR observations
struct IDCardFieldExtractor {
    static func extractKeyValuePairs(from observations: [VNRecognizedTextObservation]) -> [RecognizedKeyValue] {
        var results: [RecognizedKeyValue] = []

        func euclideanDistance(from a: CGRect, to b: CGRect) -> CGFloat {
            let dx = a.midX - b.midX
            let dy = a.midY - b.midY
            return sqrt(dx * dx + dy * dy)
        }

        let lines: [(text: String, box: CGRect, observation: VNRecognizedTextObservation)] = observations.compactMap {
            guard let text = $0.topCandidates(1).first?.string else { return nil }
            return (text.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(), $0.boundingBox, $0)
        }

        for (keyText, keyBox, keyObs) in lines {
            let keyParts = keyText.split(separator: "/").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

            guard let matchedElement = RecognizedKeyValue.DocumentElement.allCases.first(where: { element in
                keyParts.contains(where: { part in
                    element.keywords.contains(where: { keyword in
                        keyword.distance(between: part) > 0.88
                    })
                })
            }) else {
                continue
            }

            let candidates = lines.filter { candidate in
                candidate.observation != keyObs &&
                !RecognizedKeyValue.DocumentElement.allKeywords.contains(where: {
                    $0.distance(between: candidate.text) > 0.88
                })
            }

            let filteredCandidates = candidates.filter { candidate in
                let isToRight = candidate.box.minX > keyBox.midX - 0.01
                let isBelow = candidate.box.midY < keyBox.midY - 0.01
                return isToRight || isBelow
            }

            let bestMatch = filteredCandidates.min {
                euclideanDistance(from: keyBox, to: $0.box) < euclideanDistance(from: keyBox, to: $1.box)
            }

            if let match = bestMatch, isValidMatch(for: matchedElement.rawValue, value: match.text) {
                results.append(RecognizedKeyValue(
                    key: matchedElement.rawValue,
                    keyTextObservation: keyObs,
                    value: match.text,
                    valueTextObservation: match.observation
                ))
            }
        }

        return results
    }

    private static func isValidMatch(for key: String, value: String) -> Bool {
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
}