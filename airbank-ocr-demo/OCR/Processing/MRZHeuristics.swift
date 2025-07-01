//
//  MRZHeuristics.swift
//  airbank-ocr-demo
//
//  Created by Rosemary Yang on 7/2/25.
//  Copyright © 2025 Marek Přidal. All rights reserved.
//


import Foundation

enum MRZHeuristics {
    static func filterLikelyMRZ(_ lines: [RecognizedWord]) -> [RecognizedWord] {
        lines.filter {
            $0.text.count >= 20 && $0.text.range(of: "^[A-Z0-9<]+$", options: .regularExpression) != nil
        }
    }

    static func validateBlockStructure(_ lines: [RecognizedWord]) -> Bool {
        guard lines.count >= 2 else { return false }

        let lengths = lines.map { $0.text.count }
        let average = Double(lengths.reduce(0, +)) / Double(lengths.count)
        return lengths.allSatisfy { abs(Double($0) - average) < 5 }
    }
}
