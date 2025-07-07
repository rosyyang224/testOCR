//
//  QwenSummarizer.swift
//  airbank-ocr-demo
//
//  Created by Rosemary Yang on 7/7/25.
//  Copyright © 2025 Marek Přidal. All rights reserved.
//

enum QwenSummarizer {
    static func summarize(text: String) async throws -> String {
        return "Summary: " + text
    }
}
