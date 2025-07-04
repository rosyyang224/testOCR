import SwiftUI
import Vision
import VisionKit
import CoreGraphics
import PDFKit

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

struct PageVisualOverlay {
    let image: CGImage
    let textBoxes: [VNRecognizedTextObservation]
    let tableBoxes: [CGRect]
}

enum DocumentProcessor {
    @MainActor
    static func extractStructuredContent(from url: URL) async -> ([DocumentSection], [PageVisualOverlay]) {
        guard let pdf = CGPDFDocument(url as CFURL) else {
            print("Failed to open PDF")
            return ([], [])
        }

        let pageCount = pdf.numberOfPages
        var allSections: [DocumentSection] = []
        var allVisuals: [PageVisualOverlay] = []

        for pageIndex in 1...pageCount {
            guard let page = pdf.page(at: pageIndex) else { continue }
            let pageRect = page.getBoxRect(.mediaBox)

            guard let cgImage = renderCGImage(from: page, size: pageRect.size) else { continue }

            var textBoxes: [VNRecognizedTextObservation] = []
            var tableBoxes: [CGRect] = []

            await withTaskGroup(of: [DocumentSection].self) { group in
                group.addTask {
                    let sections = await extractTextBlocks(from: cgImage, pageNumber: pageIndex)
                    textBoxes = sections.compactMap { $0.boundingBox.map { VNRecognizedTextObservation(boundingBox: $0) } }
                    return sections
                }

                group.addTask {
                    let sections = await extractTables(from: cgImage, pageNumber: pageIndex)
                    tableBoxes = sections.compactMap { $0.boundingBox }
                    return sections
                }

                for await sectionGroup in group {
                    allSections.append(contentsOf: sectionGroup)
                }
            }

            allVisuals.append(PageVisualOverlay(image: cgImage, textBoxes: textBoxes, tableBoxes: tableBoxes))
        }

        return (allSections, allVisuals)
    }

    // MARK: - Convert PDF Page to CGImage
    private static func renderCGImage(from page: CGPDFPage, size: CGSize) -> CGImage? {
        let width = Int(size.width)
        let height = Int(size.height)

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1, y: -1)
        context.drawPDFPage(page)

        return context.makeImage()
    }

    // MARK: - Text Extraction
    private static func extractTextBlocks(from cgImage: CGImage, pageNumber: Int) async -> [DocumentSection] {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.automaticallyDetectsLanguage = true
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        do {
            try handler.perform([request])
            let results = request.results as? [VNRecognizedTextObservation] ?? []

            return results.compactMap { obs in
                guard let top = obs.topCandidates(1).first else { return nil }
                let text = top.string.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty else { return nil }

                let meta = DocumentSection.SectionMetadata(
                    containsNumbers: text.rangeOfCharacter(from: .decimalDigits) != nil,
                    hasPercentages: text.contains("%"),
                    hasCurrency: ["$", "€", "£", "¥", "USD", "EUR", "HKD"].contains(where: text.contains)
                )

                return DocumentSection(
                    type: classify(text: text),
                    content: text,
                    pageNumber: pageNumber,
                    boundingBox: obs.boundingBox,
                    confidence: top.confidence,
                    metadata: meta,
                    tableJSON: nil
                )
            }
        } catch {
            print("Text recognition failed:", error)
            return []
        }
    }

    // MARK: - Table Extraction
    private static func extractTables(from cgImage: CGImage, pageNumber: Int) async -> [DocumentSection] {
        do {
            let request = RecognizeDocumentsRequest()
            let results = try await request.perform(on: cgImage)
            guard let document = results.first?.document else { return [] }

            return document.tables.map { table in
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

                let content = tableJSON.map { $0.values.joined(separator: " | ") }.joined(separator: "\n")

                return DocumentSection(
                    type: .contactTable,
                    content: content,
                    pageNumber: pageNumber,
                    boundingBox: table.boundingRegion.boundingBox.cgRect,
                    confidence: 1.0,
                    metadata: nil,
                    tableJSON: tableJSON
                )
            }
        } catch {
            print("Table recognition failed:", error)
            return []
        }
    }

    // MARK: - Classification
    private static func classify(text: String) -> DocumentSection.SectionType {
        let lower = text.lowercased()
        if lower.contains("summary") || lower.contains("report") {
            return .header
        } else if lower.contains("disclaimer") || lower.contains("confidential") {
            return .footer
        } else if text.contains("•") || text.contains("- ") || text.contains("\u{2022}") {
            return .list
        } else {
            return .paragraph
        }
    }
}

// MARK: - Safe Array Indexing
fileprivate extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
