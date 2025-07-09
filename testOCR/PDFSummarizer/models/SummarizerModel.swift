//
//  SummaryModel.swift
//  airbank-ocr-demo
//
//  Created by Rosemary Yang on 7/7/25.
//  Copyright © 2025 Marek Přidal. All rights reserved.
//


enum SummarizerModel: String, CaseIterable, Identifiable {
    case foundation = "Foundation"
    case qwen = "Qwen"

    var id: String { rawValue }
}
