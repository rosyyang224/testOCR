//
//  DocumentProcessor.swift
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

struct PageVisualOverlay {
    let image: UIImage
    let textBoxes: [VNRecognizedTextObservation]
    let tableBoxes: [CGRect]
}

enum DocumentProcessor {
    @MainActor
    static func extractStructuredContent(from url: URL) async -> ([DocumentSection], [PageVisualOverlay]) {
            guard let document = CGPDFDocument(url as CFURL) else {
                print("Failed to create PDF document from URL: \(url)")
                return ([], [])
            }

            let pageCount = document.numberOfPages
            var allSections: [DocumentSection] = []
            var allVisuals: [PageVisualOverlay] = []

            for pageIndex in 1...pageCount {
                guard let page = document.page(at: pageIndex) else { continue }
                let pageRect = page.getBoxRect(.mediaBox)

                let image = UIGraphicsImageRenderer(size: pageRect.size).image { ctx in
                    ctx.cgContext.translateBy(x: 0, y: pageRect.size.height)
                    ctx.cgContext.scaleBy(x: 1.0, y: -1.0)
                    ctx.cgContext.drawPDFPage(page)
                }

                let cgImage = image.cgImage
                let imageData = image.pngData()

                var textBoxes: [VNRecognizedTextObservation] = []
                var tableBoxes: [CGRect] = []

                await withTaskGroup(of: [DocumentSection].self) { group in
                    if let cgImage {
                        group.addTask {
                            let sections = await extractTextBlocks(from: cgImage, pageNumber: pageIndex)
                            textBoxes = sections.compactMap {
                                guard let box = $0.boundingBox else { return nil }
                                return VNRecognizedTextObservation(boundingBox: box)
                            }
                            return sections
                        }
                    }

                    if let imageData {
                        group.addTask {
                            let tableSections = await extractTables(from: imageData, pageNumber: pageIndex)
                            tableBoxes = tableSections.compactMap { $0.boundingBox }
                            return tableSections
                        }
                    }

                    for await sectionList in group {
                        allSections.append(contentsOf: sectionList)
                    }
                }

                let overlay = PageVisualOverlay(image: image, textBoxes: textBoxes, tableBoxes: tableBoxes)
                allVisuals.append(overlay)
            }

            return (allSections, allVisuals)
        }

    }

    private static func extractTextAndTables(from image: UIImage, pageNumber: Int) async -> [DocumentSection] {
        var results: [DocumentSection] = []

        await withTaskGroup(of: [DocumentSection].self) { group in
            if let cgImage = image.cgImage {
                group.addTask {
                    await extractTextBlocks(from: cgImage, pageNumber: pageNumber)
                }
                group.addTask {
                    await extractTables(from: image.pngData(), pageNumber: pageNumber)
                }
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
        request.automaticallyDetectsLanguage = true
        request.usesLanguageCorrection = true

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

    private static func extractTables(from imageData: Data?, pageNumber: Int) async -> [DocumentSection] {
        guard let imageData else { return [] }

        do {
            let request = RecognizeDocumentsRequest()
            let observations = try await request.perform(on: imageData)
            guard let document = observations.first?.document else { return [] }

            var sections: [DocumentSection] = []

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

                sections.append(DocumentSection(
                    type: .contactTable,
                    content: rawContent,
                    pageNumber: pageNumber,
                    boundingBox: table.boundingRegion.boundingBox,
                    confidence: 1.0,
                    metadata: nil,
                    tableJSON: tableJSON
                ))
            }

            return sections
        } catch {
            print("Table extraction failed: \(error)")
            return []
        }
    }

    private static func classify(text: String) -> DocumentSection.SectionType {
        let lowered = text.lowercased()

        if lowered.contains("summary") || lowered.contains("report") {
            return .header
        } else if lowered.contains("disclaimer") || lowered.contains("confidential") {
            return .footer
        } else if text.contains("•") || text.contains("- ") || text.contains("\u{2022}") {
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
