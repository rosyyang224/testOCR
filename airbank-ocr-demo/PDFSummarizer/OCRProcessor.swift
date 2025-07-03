//
//  OCRProcessor.swift
//  airbank-ocr-demo
//
//  Created by Rosemary Yang on 7/3/25.
//

import UIKit
import VisionKit
import Vision

enum OCRProcessor {
    static func extractTextAndTables(from url: URL) async -> [String] {
        guard let document = CGPDFDocument(url as CFURL) else {
            print("Failed to create PDF document from URL: \(url)")
            return []
        }
        
        let pageCount = document.numberOfPages
        print("Processing PDF with \(pageCount) pages")
        
        var results: [String] = []

        for pageIndex in 1...pageCount {
            guard let page = document.page(at: pageIndex) else {
                print("Failed to get page \(pageIndex)")
                continue
            }
            
            let pageRect = page.getBoxRect(.mediaBox)
            
            // Use UIGraphicsImageRenderer instead of deprecated UIGraphicsBeginImageContext
            let renderer = UIGraphicsImageRenderer(size: pageRect.size)
            let image = renderer.image { context in
                let cgContext = context.cgContext
                
                // Set up the coordinate system for PDF rendering
                cgContext.translateBy(x: 0.0, y: pageRect.size.height)
                cgContext.scaleBy(x: 1.0, y: -1.0)
                
                // Draw the PDF page
                cgContext.drawPDFPage(page)
            }

            let text = await recognizeText(from: image)
            if !text.isEmpty {
                results.append(text)
                print("Extracted text from page \(pageIndex): \(text.prefix(100))...")
            } else {
                print("No text found on page \(pageIndex)")
            }
        }
        
        print("Total pages processed: \(results.count)")
        return results
    }

    static func recognizeText(from image: UIImage) async -> String {
        guard let cgImage = image.cgImage else {
            print("Failed to get CGImage from UIImage")
            return ""
        }
        
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        // Enable automatic language detection
        request.automaticallyDetectsLanguage = true
        
        // Set custom words if needed (for better recognition of specific terms)
        // request.customWords = ["your", "custom", "words"]

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
            let observations = request.results as? [VNRecognizedTextObservation] ?? []
            
            // Extract text with confidence filtering
            let recognizedStrings = observations.compactMap { observation in
                guard let candidate = observation.topCandidates(1).first,
                      candidate.confidence > 0.1 else { return nil }
                return candidate.string
            }
            
            let result = recognizedStrings.joined(separator: "\n")
            print("OCR extracted \(recognizedStrings.count) text segments")
            return result
            
        } catch {
            print("Text recognition failed: \(error.localizedDescription)")
            return ""
        }
    }
}
