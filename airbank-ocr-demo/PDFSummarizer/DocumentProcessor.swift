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
        case contactTable
        case header
        case footer
        case list
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
            print("❌ Failed to create PDF document from URL: \(url)")
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

            let sections = await extractPageContent(from: image, pageNumber: pageIndex)
            allSections.append(contentsOf: sections)
        }

        return allSections
    }

    @MainActor
    private static func extractPageContent(from image: UIImage, pageNumber: Int) async -> [DocumentSection] {
        guard let imageData = image.pngData() else { return [] }

        var results: [DocumentSection] = []

        do {
            let request = RecognizeDocumentsRequest()
            let observations = try await request.perform(on: imageData)

            guard let document = observations.first?.document else { return [] }

            // TEXT BLOCKS
            for textBlock in document.textBlocks {
                let rawText = textBlock.text.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !rawText.isEmpty else { continue }

                let metadata = DocumentSection.SectionMetadata(
                    containsNumbers: rawText.rangeOfCharacter(from: .decimalDigits) != nil,
                    hasPercentages: rawText.contains("%"),
                    hasCurrency: ["$", "€", "£", "¥", "USD", "EUR", "HKD"].contains { rawText.contains($0) }
                )

                let section = DocumentSection(
                    type: classify(text: rawText),
                    content: rawText,
                    pageNumber: pageNumber,
                    boundingBox: textBlock.boundingRegion.boundingBox,
                    confidence: 1.0,
                    metadata: metadata,
                    tableJSON: nil
                )
                results.append(section)
            }

            // TABLES
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

                let rawContent = tableJSON.map { $0.values.joined(separator: " | ") }.joined(separator: "\n")

                let section = DocumentSection(
                    type: .contactTable,
                    content: rawContent,
                    pageNumber: pageNumber,
                    boundingBox: table.boundingRegion.boundingBox,
                    confidence: 1.0,
                    metadata: nil,
                    tableJSON: tableJSON
                )
                results.append(section)
            }

        } catch {
            print("❌ Vision request failed: \(error)")
        }

        return results
    }

    private static func classify(text: String) -> DocumentSection.SectionType {
        let lowered = text.lowercased()

        if lowered.contains("summary") || lowered.contains("report") {
            return .header
        } else if lowered.contains("disclaimer") || lowered.contains("confidential") {
            return .footer
        } else if text.contains("\u{2022}") || text.contains("- ") || text.contains("•") {
            return .list
        } else {
            return .paragraph
        }
    }
}

// MARK: - Safe Array Access
fileprivate extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Coordinate Helpers
fileprivate extension CGRect {
    /// Converts Vision normalized coordinates to UIKit flipped coordinate space.
    func verticallyFlipped() -> CGRect {
        return CGRect(x: origin.x, y: 1.0 - origin.y - height, width: width, height: height)
    }
}
