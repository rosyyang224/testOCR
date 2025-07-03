// DocumentProcessor.swift (Generalized Text + Table JSON Extraction)
// Uses WWDC25 VisionKit for new table parsing capabilities

import UIKit
import VisionKit
import Vision

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

            for await section in group {
                results.append(contentsOf: section)
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

    private static func extractTablesWithJSON(from cgImage: CGImage, pageNumber: Int) async -> [DocumentSection] {
        let tableDetection = VNDetectDocumentTablesRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        do {
            try handler.perform([tableDetection])
            let tables = tableDetection.results ?? []

            var sections: [DocumentSection] = []
            for table in tables {
                let tableReadRequest = VNReadDocumentTableRequest(table: table)
                try handler.perform([tableReadRequest])

                guard let tableResult = tableReadRequest.results?.first else { continue }
                let jsonRows: [[String: String]] = convertToJSON(tableResult)
                let rawText = jsonRows.map { $0.values.joined(separator: " | ") }.joined(separator: "\n")

                sections.append(DocumentSection(
                    type: .detectedTable,
                    content: rawText,
                    pageNumber: pageNumber,
                    boundingBox: table.boundingBox,
                    confidence: table.confidence,
                    metadata: nil,
                    tableJSON: jsonRows
                ))
            }

            return sections
        } catch {
            print("Table detection or parsing failed: \(error.localizedDescription)")
            return []
        }
    }

    private static func convertToJSON(_ table: VNDocumentTable) -> [[String: String]] {
        guard !table.rows.isEmpty else { return [] }
        let headers = table.rows.first?.cells.map { $0.text ?? "" } ?? []
        var jsonRows: [[String: String]] = []

        for row in table.rows.dropFirst() {
            var dict: [String: String] = [:]
            for (i, cell) in row.cells.enumerated() {
                let key = headers[safe: i] ?? "Column \(i+1)"
                dict[key] = cell.text ?? ""
            }
            jsonRows.append(dict)
        }
        return jsonRows
    }

    private static func classify(text: String) -> DocumentSection.SectionType {
        let lowered = text.lowercased()
        if lowered.count < 50 && (lowered.contains("summary") || lowered.contains("report")) {
            return .headerInfo
        } else if lowered.contains("disclaimer") || lowered.contains("confidential") {
            return .footerDisclaimer
        } else if text.contains("\u2022") || text.contains("-") || text.contains("•") {
            return .list
        } else {
            return .paragraph
        }
    }
}

// Safe index for array
fileprivate extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
