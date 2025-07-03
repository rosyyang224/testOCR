//
//  DocumentProcessor.swift
//  airbank-ocr-demo
//
//  Created by Rosemary Yang on 7/3/25.
//  Copyright © 2025 Marek Přidal. All rights reserved.
//
import UIKit
import VisionKit
import Vision

struct DocumentSection {
    let type: SectionType
    let content: String
    let pageNumber: Int
    let boundingBox: CGRect?
    
    enum SectionType {
        case paragraph
        case table
        case list
        case header
        case unknown
    }
}

enum DocumentProcessor {
    static func extractStructuredContent(from url: URL) async -> [DocumentSection] {
        guard let document = CGPDFDocument(url as CFURL) else {
            print("Failed to create PDF document from URL: \(url)")
            return []
        }
        
        let pageCount = document.numberOfPages
        print("Processing PDF with \(pageCount) pages using Vision document reading")
        
        var allSections: [DocumentSection] = []
        
        for pageIndex in 1...pageCount {
            guard let page = document.page(at: pageIndex) else {
                print("Failed to get page \(pageIndex)")
                continue
            }
            
            let pageRect = page.getBoxRect(.mediaBox)
            let renderer = UIGraphicsImageRenderer(size: pageRect.size)
            let image = renderer.image { context in
                let cgContext = context.cgContext
                cgContext.translateBy(x: 0.0, y: pageRect.size.height)
                cgContext.scaleBy(x: 1.0, y: -1.0)
                cgContext.drawPDFPage(page)
            }
            
            let sections = await extractDocumentStructure(from: image, pageNumber: pageIndex)
            allSections.append(contentsOf: sections)
        }
        
        print("Extracted \(allSections.count) structured sections from document")
        return allSections
    }
    
    private static func extractDocumentStructure(from image: UIImage, pageNumber: Int) async -> [DocumentSection] {
        guard let cgImage = image.cgImage else {
            print("Failed to get CGImage from UIImage")
            return []
        }
        
        var sections: [DocumentSection] = []
        
        // Extract structured document content using new Vision APIs
        await withTaskGroup(of: [DocumentSection].self) { group in
            // Extract tables
            group.addTask {
                await extractTables(from: cgImage, pageNumber: pageNumber)
            }
            
            // Extract paragraphs and text blocks
            group.addTask {
                await extractTextBlocks(from: cgImage, pageNumber: pageNumber)
            }
            
            // Extract lists
            group.addTask {
                await extractLists(from: cgImage, pageNumber: pageNumber)
            }
            
            for await taskSections in group {
                sections.append(contentsOf: taskSections)
            }
        }
        
        // Sort sections by vertical position for proper reading order
        return sections.sorted { section1, section2 in
            guard let box1 = section1.boundingBox, let box2 = section2.boundingBox else {
                return false
            }
            return box1.minY < box2.minY
        }
    }
    
    private static func extractTables(from cgImage: CGImage, pageNumber: Int) async -> [DocumentSection] {
        let request = VNDetectDocumentTablesRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
            guard let observations = request.results else { return [] }
            
            var tableSections: [DocumentSection] = []
            
            for (index, observation) in observations.enumerated() {
                // Extract table content using new Vision table reading
                let tableContent = await extractTableContent(from: cgImage, table: observation)
                
                let section = DocumentSection(
                    type: .table,
                    content: "Table \(index + 1):\n\(tableContent)",
                    pageNumber: pageNumber,
                    boundingBox: observation.boundingBox
                )
                tableSections.append(section)
            }
            
            print("Extracted \(tableSections.count) tables from page \(pageNumber)")
            return tableSections
            
        } catch {
            print("Table detection failed: \(error.localizedDescription)")
            return []
        }
    }
    
    private static func extractTableContent(from cgImage: CGImage, table: VNDetectedDocumentTableObservation) async -> String {
        // Use new Vision API to read table structure and content
        let request = VNReadDocumentTableRequest(table: table)
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
            guard let result = request.results?.first else { return "Unable to read table content" }
            
            // Format table data into readable text
            var tableText = ""
            for (rowIndex, row) in result.rows.enumerated() {
                var rowText = ""
                for (colIndex, cell) in row.cells.enumerated() {
                    if colIndex > 0 { rowText += " | " }
                    rowText += cell.text ?? ""
                }
                if rowIndex == 0 {
                    tableText += rowText + "\n" + String(repeating: "-", count: rowText.count) + "\n"
                } else {
                    tableText += rowText + "\n"
                }
            }
            
            return tableText
            
        } catch {
            print("Table reading failed: \(error.localizedDescription)")
            return "Table content could not be extracted"
        }
    }
    
    private static func extractTextBlocks(from cgImage: CGImage, pageNumber: Int) async -> [DocumentSection] {
        let request = VNDetectDocumentTextBlocksRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
            guard let observations = request.results else { return [] }
            
            var textSections: [DocumentSection] = []
            
            for observation in observations {
                let textContent = await readTextBlock(from: cgImage, textBlock: observation)
                
                let sectionType: DocumentSection.SectionType = determineSectionType(textContent)
                
                let section = DocumentSection(
                    type: sectionType,
                    content: textContent,
                    pageNumber: pageNumber,
                    boundingBox: observation.boundingBox
                )
                textSections.append(section)
            }
            
            print("Extracted \(textSections.count) text blocks from page \(pageNumber)")
            return textSections
            
        } catch {
            print("Text block detection failed: \(error.localizedDescription)")
            return []
        }
    }
    
    private static func readTextBlock(from cgImage: CGImage, textBlock: VNDetectedDocumentTextBlockObservation) async -> String {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.automaticallyDetectsLanguage = true
        
        // Crop image to text block region for better accuracy
        let croppedImage = cropImage(cgImage, to: textBlock.boundingBox)
        let handler = VNImageRequestHandler(cgImage: croppedImage, options: [:])
        
        do {
            try handler.perform([request])
            let observations = request.results as? [VNRecognizedTextObservation] ?? []
            
            let recognizedStrings = observations.compactMap { observation in
                guard let candidate = observation.topCandidates(1).first,
                      candidate.confidence > 0.2 else { return nil }
                return candidate.string
            }
            
            return recognizedStrings.joined(separator: "\n")
            
        } catch {
            print("Text recognition failed: \(error.localizedDescription)")
            return ""
        }
    }
    
    private static func extractLists(from cgImage: CGImage, pageNumber: Int) async -> [DocumentSection] {
        let request = VNDetectDocumentListsRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
            guard let observations = request.results else { return [] }
            
            var listSections: [DocumentSection] = []
            
            for (index, observation) in observations.enumerated() {
                let listContent = await readListContent(from: cgImage, list: observation)
                
                let section = DocumentSection(
                    type: .list,
                    content: "List \(index + 1):\n\(listContent)",
                    pageNumber: pageNumber,
                    boundingBox: observation.boundingBox
                )
                listSections.append(section)
            }
            
            print("Extracted \(listSections.count) lists from page \(pageNumber)")
            return listSections
            
        } catch {
            print("List detection failed: \(error.localizedDescription)")
            return []
        }
    }
    
    private static func readListContent(from cgImage: CGImage, list: VNDetectedDocumentListObservation) async -> String {
        // Extract list items with proper formatting
        var listText = ""
        for (index, item) in list.items.enumerated() {
            let itemText = await readTextBlock(from: cgImage, textBlock: item)
            listText += "• \(itemText)\n"
        }
        return listText
    }
    
    private static func determineSectionType(_ content: String) -> DocumentSection.SectionType {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Simple heuristics to determine section type
        if trimmed.count < 100 && (trimmed.contains("Chapter") || trimmed.contains("Section") || trimmed.allSatisfy { $0.isUppercase || $0.isWhitespace }) {
            return .header
        } else if trimmed.contains("•") || trimmed.contains("-") || trimmed.contains("1.") {
            return .list
        } else {
            return .paragraph
        }
    }
    
    private static func cropImage(_ cgImage: CGImage, to normalizedRect: CGRect) -> CGImage {
        let imageWidth = CGFloat(cgImage.width)
        let imageHeight = CGFloat(cgImage.height)
        
        let cropRect = CGRect(
            x: normalizedRect.minX * imageWidth,
            y: (1.0 - normalizedRect.maxY) * imageHeight, // Vision uses flipped coordinates
            width: normalizedRect.width * imageWidth,
            height: normalizedRect.height * imageHeight
        )
        
        return cgImage.cropping(to: cropRect) ?? cgImage
    }
}