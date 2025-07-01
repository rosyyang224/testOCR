//
//  MRZProcessor.swift
//  airbank-ocr-demo
//
//  Created by Rosemary Yang on 7/1/25.
//  Copyright © 2025 Marek Přidal. All rights reserved.
//


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

        return mrzCandidates.sorted { $0.boundingBox.minY < $1.boundingBox.minY }
    }

    /// Determines whether the grouped MRZ candidates are valid MRZ block (TD3 or TD1)
    static func isLikelyMRZBlock(_ mrzLines: [RecognizedWord]) -> Bool {
        // Typically 2 or 3 lines
        guard mrzLines.count == 2 || mrzLines.count == 3 else { return false }

        // Vertically aligned (i.e., at bottom of the document)
        let maxY = mrzLines.map { $0.boundingBox.maxY }.max() ?? 0
        return maxY < 0.3 // bottom 30% of image
    }
}