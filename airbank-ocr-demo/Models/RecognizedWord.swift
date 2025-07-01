//
//  RecognizedWord.swift
//  airbank-ocr-demo
//
//  Created by Rosemary Yang on 7/1/25.
//  Copyright © 2025 Marek Přidal. All rights reserved.
//


import Foundation
import CoreGraphics

struct RecognizedWord {
    let text: String
    let boundingBox: CGRect
}
