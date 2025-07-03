//
//  OCRProcessor.swift
//  airbank-ocr-demo
//
//  Created by Rosemary Yang on 7/2/25.
//  Copyright © 2025 Marek Přidal. All rights reserved.
//


// OCRProcessor.swift
// Utility for extracting text using Vision OCR

import UIKit
import Vision

enum OCRProcessor {
    static func extractText(from image: UIImage) async -> [String] {
        guard let cgImage = image.cgImage else { return [] }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
            let results = request.results as? [VNRecognizedTextObservation] ?? []
            return results.compactMap { $0.topCandidates(1).first?.string }
        } catch {
            return []
        }
    }
    
    static func extractRawObservations(from image: UIImage) async -> [VNRecognizedTextObservation] {
        guard let cgImage = image.cgImage else { return [] }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
            return request.results as? [VNRecognizedTextObservation] ?? []
        } catch {
            return []
        }
    }

    
}
