//
//  ParserMethod.swift
//  airbank-ocr-demo
//
//  Created by Rosemary Yang on 7/9/25.
//  Copyright © 2025 Marek Přidal. All rights reserved.
//


enum ParserModel: String, CaseIterable, Identifiable {
    case docling = "Docling"
    case pypdf = "PyPDF"

    var id: String { rawValue }
}
