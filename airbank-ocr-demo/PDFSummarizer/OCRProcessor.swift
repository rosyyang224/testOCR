// OCRProcessor.swift
import UIKit
import VisionKit
import Vision

enum OCRProcessor {
    static func extractTextAndTables(from url: URL) async -> [String] {
        guard let document = CGPDFDocument(url as CFURL) else { return [] }
        let pageCount = document.numberOfPages

        var results: [String] = []

        for pageIndex in 1...pageCount {
            guard let page = document.page(at: pageIndex) else { continue }
            let pageRect = page.getBoxRect(.mediaBox)
            UIGraphicsBeginImageContext(pageRect.size)
            guard let context = UIGraphicsGetCurrentContext() else { continue }

            context.translateBy(x: 0.0, y: pageRect.size.height)
            context.scaleBy(x: 1.0, y: -1.0)
            context.drawPDFPage(page)
            guard let image = UIGraphicsGetImageFromCurrentImageContext() else { continue }
            UIGraphicsEndImageContext()

            let text = await recognizeText(from: image)
            results.append(text)
        }
        return results
    }

    static func recognizeText(from image: UIImage) async -> String {
        guard let cgImage = image.cgImage else { return "" }
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
            let observations = request.results as? [VNRecognizedTextObservation] ?? []
            return observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: " ")
        } catch {
            print("Text recognition failed: \(error)")
            return ""
        }
    }
}
