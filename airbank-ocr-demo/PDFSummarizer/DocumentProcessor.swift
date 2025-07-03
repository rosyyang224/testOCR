//
//  DocumentProcessor.swift
//  Generalized Text + Table JSON Extraction (iOS 18 / macOS 15+)
//

import UIKit
import Vision
import VisionKit

struct DocumentSection {
    let type: SectionType
    let content: String
    let pageNumber: Int
    let boundingBox: CGRect?
    let confidence: Float
    let metadata: SectionMetadata?
    let tableJSON: [[String: String]]?

    enum SectionType {
        case paragraph
        case headerInfo
        case footerDisclaimer
        case list
        case detectedTable
        case unknown
    }

    struct SectionMetadata {
        let containsNumbers: Bool
        let hasPercentages: Bool
        let hasCurrency: Bool
    }
}

enum DocumentProcessor {
    @MainActor
    static func extractStructuredContent(from url: URL) async -> [DocumentSection] {
        guard let document = CGPDFDocument(url as CFURL) else {
            print("Failed to create PDF document from URL: \(url)")
            return []
        }

        let pageCount = document.numberOfPages
        var allSections: [DocumentSection] = []

        for pageIndex in 1...pageCount {
            guard let page = document.page(at: pageIndex) else { continue }
            let pageRect = page.getBoxRect(.mediaBox)
            let image = UIGraphicsImageRenderer(size: pageRect.size).image { ctx in
                ctx.cgContext.translateBy(x: 0, y: pageRect.size.height)
                ctx.cgContext.scaleBy(x: 1.0, y: -1.0)
                ctx.cgContext.drawPDFPage(page)
            }

            let sections = await extractTextAndTables(from: image, pageNumber: pageIndex)
            allSections.append(contentsOf: sections)
        }

        return allSections
    }

    private static func extractTextAndTables(from image: UIImage, pageNumber: Int) async -> [DocumentSection] {
        guard let cgImage = image.cgImage else { return [] }

        var results: [DocumentSection] = []

        await withTaskGroup(of: [DocumentSection].self) { group in
            group.addTask {
                await extractTextBlocks(from: cgImage, pageNumber: pageNumber)
            }
            group.addTask {
                await extractTablesWithJSON(from: cgImage, pageNumber: pageNumber)
            }

            for await sectionList in group {
                results.append(contentsOf: sectionList)
            }
        }

        return results
    }

    private static func extractTextBlocks(from cgImage: CGImage, pageNumber: Int) async -> [DocumentSection] {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.automaticallyDetectsLanguage = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
            let observations = request.results as? [VNRecognizedTextObservation] ?? []

            return observations.compactMap { observation in
                guard let topCandidate = observation.topCandidates(1).first else { return nil }
                let text = topCandidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty else { return nil }

                let meta = DocumentSection.SectionMetadata(
                    containsNumbers: text.rangeOfCharacter(from: .decimalDigits) != nil,
                    hasPercentages: text.contains("%"),
                    hasCurrency: ["$", "€", "£", "¥", "USD", "EUR", "HKD"].contains { text.contains($0) }
                )

                return DocumentSection(
                    type: classify(text: text),
                    content: text,
                    pageNumber: pageNumber,
                    boundingBox: observation.boundingBox,
                    confidence: topCandidate.confidence,
                    metadata: meta,
                    tableJSON: nil
                )
            }
        } catch {
            print("Text recognition failed: \(error.localizedDescription)")
            return []
        }
    }

    @available(iOS 18.0, macOS 15.0, *)
    private static func extractTablesWithJSON(from cgImage: CGImage, pageNumber: Int) async -> [DocumentSection] {
        let request = RecognizeDocumentsRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        do {
            try handler.perform([request])
            guard let observations = request.results as? [DocumentObservation] else { return [] }

            var sections: [DocumentSection] = []

            for document in observations {
                for table in document.tables {
                    let headers = table.rows.first?.map { $0.content.text.transcript } ?? []
                    let dataRows = table.rows.dropFirst()

                    let tableJSON: [[String: String]] = dataRows.map { row in
                        var dict: [String: String] = [:]
                        for (i, cell) in row.enumerated() {
                            let key = headers[safe: i] ?? "Column \(i + 1)"
                            dict[key] = cell.content.text.transcript
                        }
                        return dict
                    }

                    let rawText = tableJSON
                        .map { $0.values.joined(separator: " | ") }
                        .joined(separator: "\n")

                    sections.append(DocumentSection(
                        type: .detectedTable,
                        content: rawText,
                        pageNumber: pageNumber,
                        boundingBox: table.boundingRegion.boundingBox,
                        confidence: 1.0,
                        metadata: nil,
                        tableJSON: tableJSON
                    ))
                }
            }

            return sections
        } catch {
            print("Table detection failed: \(error.localizedDescription)")
            return []
        }
    }

    private static func classify(text: String) -> DocumentSection.SectionType {
        let lowered = text.lowercased()
        if lowered.count < 50 && (lowered.contains("summary") || lowered.contains("report")) {
            return .headerInfo
        } else if lowered.contains("disclaimer") || lowered.contains("confidential") {
            return .footerDisclaimer
        } else if text.contains("\u{2022}") || text.contains("-") || text.contains("•") {
            return .list
        } else {
            return .paragraph
        }
    }
}

// MARK: - Safe Array Access
fileprivate extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
