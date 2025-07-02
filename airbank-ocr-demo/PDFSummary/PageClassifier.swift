//
//  PageClassifier.swift
//  airbank-ocr-demo
//
//  Created by Rosemary Yang on 7/2/25.
//  Copyright © 2025 Marek Přidal. All rights reserved.
//


// PageClassifier.swift
// Logic to determine if a page is a chart or text

import Foundation

enum PageClassifier {
    static func classify(_ lines: [String]) -> String {
        let numericLines = lines.filter { $0.range(of: #"\d{1,3}(,\d{3})*(\.\d+)?"#, options: .regularExpression) != nil }
        let hasTableHeaders = lines.contains(where: { $0.uppercased().contains("MARKET VALUE") || $0.uppercased().contains("TOTAL") })
        let hasParagraphs = lines.contains(where: { $0.split(separator: " ").count > 15 })

        if hasParagraphs && numericLines.count < lines.count / 4 {
            return "text"
        } else if hasTableHeaders || numericLines.count > lines.count / 3 {
            return "chart"
        } else {
            return "unknown"
        }
    }
}
