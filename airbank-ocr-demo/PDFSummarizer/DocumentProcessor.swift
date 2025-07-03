//
//  DocumentProcessor.swift
//  airbank-ocr-demo
//
//  Created by Rosemary Yang on 7/3/25.
//

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
    
    enum SectionType {
        case financialTable
        case portfolioSummary
        case currencyData
        case equityHoldings
        case bondHoldings
        case derivativesData
        case performanceChart
        case headerInfo
        case footerDisclaimer
        case paragraph
        case list
        case unknown
    }
    
    struct SectionMetadata {
        let isFinancialData: Bool
        let containsNumbers: Bool
        let hasPercentages: Bool
        let hasCurrency: Bool
        let tableStructure: TableStructure?
        let chartType: ChartType?
    }
    
    struct TableStructure {
        let columnCount: Int
        let rowCount: Int
        let hasHeaders: Bool
        let financialColumns: [String]
    }
    
    enum ChartType {
        case pie
        case bar
        case line
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
        print("Processing financial document with \(pageCount) pages")
        
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
            
            let sections = await extractFinancialDocumentStructure(from: image, pageNumber: pageIndex)
            allSections.append(contentsOf: sections)
        }
        
        print("Extracted \(allSections.count) structured sections from financial document")
        return allSections
    }
    
    private static func extractFinancialDocumentStructure(from image: UIImage, pageNumber: Int) async -> [DocumentSection] {
        guard let cgImage = image.cgImage else {
            print("Failed to get CGImage from UIImage")
            return []
        }
        
        var sections: [DocumentSection] = []
        
        await withTaskGroup(of: [DocumentSection].self) { group in
            // Extract financial tables with specialized handling
            group.addTask {
                await extractFinancialTables(from: cgImage, pageNumber: pageNumber)
            }
            
            // Extract header/footer information
            group.addTask {
                await extractHeaderFooterInfo(from: cgImage, pageNumber: pageNumber)
            }
            
            // Extract charts and graphs
            group.addTask {
                await extractChartsAndGraphs(from: cgImage, pageNumber: pageNumber)
            }
            
            // Extract currency and numerical data blocks
            group.addTask {
                await extractFinancialTextBlocks(from: cgImage, pageNumber: pageNumber)
            }
            
            for await taskSections in group {
                sections.append(contentsOf: taskSections)
            }
        }
        
        // Sort sections by vertical position and classify financial content
        let sortedSections = sections.sorted { section1, section2 in
            guard let box1 = section1.boundingBox, let box2 = section2.boundingBox else {
                return false
            }
            return box1.minY < box2.minY
        }
        
        return await classifyFinancialSections(sortedSections)
    }
    
    private static func extractFinancialTables(from cgImage: CGImage, pageNumber: Int) async -> [DocumentSection] {
        let request = VNDetectDocumentTablesRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
            guard let observations = request.results else { return [] }
            
            var tableSections: [DocumentSection] = []
            
            for (index, observation) in observations.enumerated() {
                let tableContent = await extractFinancialTableContent(from: cgImage, table: observation)
                let metadata = analyzeTableStructure(tableContent)
                
                let section = DocumentSection(
                    type: determineFinancialTableType(tableContent),
                    content: "Financial Table \(index + 1):\n\(tableContent)",
                    pageNumber: pageNumber,
                    boundingBox: observation.boundingBox,
                    confidence: observation.confidence,
                    metadata: DocumentSection.SectionMetadata(
                        isFinancialData: true,
                        containsNumbers: true,
                        hasPercentages: tableContent.contains("%"),
                        hasCurrency: containsCurrencySymbols(tableContent),
                        tableStructure: metadata,
                        chartType: nil
                    )
                )
                tableSections.append(section)
            }
            
            print("Extracted \(tableSections.count) financial tables from page \(pageNumber)")
            return tableSections
            
        } catch {
            print("Financial table detection failed: \(error.localizedDescription)")
            return []
        }
    }
    
    private static func extractFinancialTableContent(from cgImage: CGImage, table: VNDetectedDocumentTableObservation) async -> String {
        let request = VNReadDocumentTableRequest(table: table)
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
            guard let result = request.results?.first else { return "Unable to read table content" }
            
            var tableText = ""
            let financialColumns = ["Market Value", "Cost", "P/(L)", "Currency", "Price", "Shares", "Face Value", "%"]
            
            for (rowIndex, row) in result.rows.enumerated() {
                var rowText = ""
                for (colIndex, cell) in row.cells.enumerated() {
                    if colIndex > 0 { rowText += " | " }
                    let cellText = cell.text ?? ""
                    
                    // Format financial data for better readability
                    if isFinancialValue(cellText) {
                        rowText += formatFinancialValue(cellText)
                    } else {
                        rowText += cellText
                    }
                }
                
                if rowIndex == 0 {
                    // Header row formatting
                    tableText += rowText + "\n" + String(repeating: "=", count: min(rowText.count, 100)) + "\n"
                } else {
                    tableText += rowText + "\n"
                }
            }
            
            return tableText
            
        } catch {
            print("Financial table reading failed: \(error.localizedDescription)")
            return "Financial table content could not be extracted"
        }
    }
    
    private static func extractHeaderFooterInfo(from cgImage: CGImage, pageNumber: Int) async -> [DocumentSection] {
        let imageHeight = CGFloat(cgImage.height)
        let imageWidth = CGFloat(cgImage.width)
        
        // Define header and footer regions (top 15% and bottom 15%)
        let headerRect = CGRect(x: 0, y: 0, width: imageWidth, height: imageHeight * 0.15)
        let footerRect = CGRect(x: 0, y: imageHeight * 0.85, width: imageWidth, height: imageHeight * 0.15)
        
        var sections: [DocumentSection] = []
        
        // Extract header
        if let headerImage = cgImage.cropping(to: headerRect) {
            let headerText = await recognizeText(from: headerImage, accuracy: .accurate)
            if !headerText.isEmpty {
                sections.append(DocumentSection(
                    type: .headerInfo,
                    content: headerText,
                    pageNumber: pageNumber,
                    boundingBox: CGRect(x: 0, y: 0.85, width: 1.0, height: 0.15),
                    confidence: 0.9,
                    metadata: DocumentSection.SectionMetadata(
                        isFinancialData: false,
                        containsNumbers: headerText.rangeOfCharacter(from: .decimalDigits) != nil,
                        hasPercentages: false,
                        hasCurrency: false,
                        tableStructure: nil,
                        chartType: nil
                    )
                ))
            }
        }
        
        // Extract footer
        if let footerImage = cgImage.cropping(to: footerRect) {
            let footerText = await recognizeText(from: footerImage, accuracy: .accurate)
            if !footerText.isEmpty {
                sections.append(DocumentSection(
                    type: .footerDisclaimer,
                    content: footerText,
                    pageNumber: pageNumber,
                    boundingBox: CGRect(x: 0, y: 0, width: 1.0, height: 0.15),
                    confidence: 0.9,
                    metadata: DocumentSection.SectionMetadata(
                        isFinancialData: false,
                        containsNumbers: false,
                        hasPercentages: false,
                        hasCurrency: false,
                        tableStructure: nil,
                        chartType: nil
                    )
                ))
            }
        }
        
        return sections
    }
    
    private static func extractChartsAndGraphs(from cgImage: CGImage, pageNumber: Int) async -> [DocumentSection] {
        // Use Vision to detect potential chart regions
        let request = VNDetectRectanglesRequest()
        request.minimumSize = 0.1
        request.maximumObservations = 10
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
            guard let observations = request.results else { return [] }
            
            var chartSections: [DocumentSection] = []
            
            for observation in observations {
                // Check if the rectangle might contain a chart
                if isLikelyChart(observation, imageSize: CGSize(width: cgImage.width, height: cgImage.height)) {
                    let chartType = await analyzeChartType(from: cgImage, in: observation.boundingBox)
                    
                    let section = DocumentSection(
                        type: .performanceChart,
                        content: "Chart detected - \(chartType.rawValue)",
                        pageNumber: pageNumber,
                        boundingBox: observation.boundingBox,
                        confidence: observation.confidence,
                        metadata: DocumentSection.SectionMetadata(
                            isFinancialData: true,
                            containsNumbers: false,
                            hasPercentages: false,
                            hasCurrency: false,
                            tableStructure: nil,
                            chartType: chartType
                        )
                    )
                    chartSections.append(section)
                }
            }
            
            return chartSections
            
        } catch {
            print("Chart detection failed: \(error.localizedDescription)")
            return []
        }
    }
    
    private static func extractFinancialTextBlocks(from cgImage: CGImage, pageNumber: Int) async -> [DocumentSection] {
        let request = VNDetectDocumentTextBlocksRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
            guard let observations = request.results else { return [] }
            
            var textSections: [DocumentSection] = []
            
            for observation in observations {
                let textContent = await readFinancialTextBlock(from: cgImage, textBlock: observation)
                
                if !textContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    let metadata = analyzeFinancialTextMetadata(textContent)
                    let sectionType = determineFinancialSectionType(textContent, metadata: metadata)
                    
                    let section = DocumentSection(
                        type: sectionType,
                        content: textContent,
                        pageNumber: pageNumber,
                        boundingBox: observation.boundingBox,
                        confidence: observation.confidence,
                        metadata: metadata
                    )
                    textSections.append(section)
                }
            }
            
            print("Extracted \(textSections.count) financial text blocks from page \(pageNumber)")
            return textSections
            
        } catch {
            print("Financial text block detection failed: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - Helper Functions
    
    private static func determineFinancialTableType(_ content: String) -> DocumentSection.SectionType {
        let lowercased = content.lowercased()
        
        if lowercased.contains("portfolio") || lowercased.contains("valuation") {
            return .portfolioSummary
        } else if lowercased.contains("currency") || lowercased.contains("exchange rate") {
            return .currencyData
        } else if lowercased.contains("equity") || lowercased.contains("stock") || lowercased.contains("shares") {
            return .equityHoldings
        } else if lowercased.contains("bond") || lowercased.contains("debt") || lowercased.contains("note") {
            return .bondHoldings
        } else if lowercased.contains("derivative") || lowercased.contains("option") || lowercased.contains("swap") {
            return .derivativesData
        } else {
            return .financialTable
        }
    }
    
    private static func analyzeTableStructure(_ content: String) -> DocumentSection.TableStructure {
        let lines = content.components(separatedBy: .newlines)
        let nonEmptyLines = lines.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        let columnCount = nonEmptyLines.first?.components(separatedBy: "|").count ?? 0
        let rowCount = nonEmptyLines.count
        
        let financialColumns = ["Market Value", "Cost", "P/(L)", "Currency", "Price", "Shares", "Face Value", "%", "USD", "EUR", "GBP", "HKD", "JPY"]
        
        return DocumentSection.TableStructure(
            columnCount: columnCount,
            rowCount: rowCount,
            hasHeaders: rowCount > 0,
            financialColumns: financialColumns
        )
    }
    
    private static func analyzeFinancialTextMetadata(_ content: String) -> DocumentSection.SectionMetadata {
        let containsNumbers = content.rangeOfCharacter(from: .decimalDigits) != nil
        let hasPercentages = content.contains("%")
        let hasCurrency = containsCurrencySymbols(content)
        let isFinancialData = containsNumbers && (hasCurrency || hasPercentages || containsFinancialKeywords(content))
        
        return DocumentSection.SectionMetadata(
            isFinancialData: isFinancialData,
            containsNumbers: containsNumbers,
            hasPercentages: hasPercentages,
            hasCurrency: hasCurrency,
            tableStructure: nil,
            chartType: nil
        )
    }
    
    private static func determineFinancialSectionType(_ content: String, metadata: DocumentSection.SectionMetadata) -> DocumentSection.SectionType {
        let lowercased = content.lowercased()
        
        if lowercased.contains("portfolio") && metadata.isFinancialData {
            return .portfolioSummary
        } else if metadata.hasCurrency {
            return .currencyData
        } else if lowercased.contains("equity") || lowercased.contains("stock") {
            return .equityHoldings
        } else if lowercased.contains("bond") || lowercased.contains("debt") {
            return .bondHoldings
        } else if lowercased.contains("derivative") {
            return .derivativesData
        } else if metadata.isFinancialData {
            return .financialTable
        } else {
            return .paragraph
        }
    }
    
    private static func containsCurrencySymbols(_ text: String) -> Bool {
        let currencySymbols = ["$", "€", "£", "¥", "USD", "EUR", "GBP", "HKD", "JPY", "SGD"]
        return currencySymbols.contains { text.contains($0) }
    }
    
    private static func containsFinancialKeywords(_ text: String) -> Bool {
        let keywords = ["market value", "cost", "profit", "loss", "shares", "price", "yield", "return", "portfolio", "investment", "bond", "equity", "derivative"]
        let lowercased = text.lowercased()
        return keywords.contains { lowercased.contains($0) }
    }
    
    private static func isFinancialValue(_ text: String) -> Bool {
        let pattern = #"[\$€£¥]?[0-9,]+\.?[0-9]*\%?|[0-9,]+\.?[0-9]*[\$€£¥%]"#
        return text.range(of: pattern, options: .regularExpression) != nil
    }
    
    private static func formatFinancialValue(_ text: String) -> String {
        // Add proper formatting for financial values
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private static func isLikelyChart(_ observation: VNRectangleObservation, imageSize: CGSize) -> Bool {
        let rect = observation.boundingBox
        let area = rect.width * rect.height
        
        // Charts are typically larger rectangles with specific aspect ratios
        return area > 0.05 && rect.width > 0.2 && rect.height > 0.1
    }
    
    private static func analyzeChartType(from cgImage: CGImage, in boundingBox: CGRect) async -> DocumentSection.ChartType {
        // Simple heuristic - in practice, you might use more sophisticated analysis
        let aspectRatio = boundingBox.width / boundingBox.height
        
        if aspectRatio > 1.5 {
            return .bar
        } else if aspectRatio < 0.8 {
            return .pie
        } else {
            return .line
        }
    }
    
    private static func readFinancialTextBlock(from cgImage: CGImage, textBlock: VNDetectedDocumentTextBlockObservation) async -> String {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.automaticallyDetectsLanguage = true
        
        // Configure for financial text recognition
        request.customWords = ["USD", "EUR", "GBP", "HKD", "JPY", "MSIP", "MSBAL", "Morgan Stanley", "Portfolio", "Valuation"]
        
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
            print("Financial text recognition failed: \(error.localizedDescription)")
            return ""
        }
    }
    
    private static func recognizeText(from cgImage: CGImage, accuracy: VNRequestTextRecognitionLevel) async -> String {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = accuracy
        request.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
            let observations = request.results as? [VNRecognizedTextObservation] ?? []
            
            let recognizedStrings = observations.compactMap { observation in
                guard let candidate = observation.topCandidates(1).first,
                      candidate.confidence > 0.1 else { return nil }
                return candidate.string
            }
            
            return recognizedStrings.joined(separator: "\n")
            
        } catch {
            print("Text recognition failed: \(error.localizedDescription)")
            return ""
        }
    }
    
    private static func classifyFinancialSections(_ sections: [DocumentSection]) async -> [DocumentSection] {
        // Post-process sections to improve classification based on context
        var improvedSections: [DocumentSection] = []
        
        for (index, section) in sections.enumerated() {
            var improvedSection = section
            
            // Use context from surrounding sections to improve classification
            if section.type == .paragraph || section.type == .unknown {
                let context = getContextFromSurroundingSections(sections, currentIndex: index)
                let improvedType = refineFinancialSectionType(section.content, context: context)
                
                improvedSection = DocumentSection(
                    type: improvedType,
                    content: section.content,
                    pageNumber: section.pageNumber,
                    boundingBox: section.boundingBox,
                    confidence: section.confidence,
                    metadata: section.metadata
                )
            }
            
            improvedSections.append(improvedSection)
        }
        
        return improvedSections
    }
    
    private static func getContextFromSurroundingSections(_ sections: [DocumentSection], currentIndex: Int) -> String {
        let range = max(0, currentIndex - 2)...<min(sections.count, currentIndex + 3)
        return sections[range].map { $0.content }.joined(separator: " ")
    }
    
    private static func refineFinancialSectionType(_ content: String, context: String) -> DocumentSection.SectionType {
        let combinedText = (content + " " + context).lowercased()
        
        if combinedText.contains("cash") && combinedText.contains("equivalent") {
            return .currencyData
        } else if combinedText.contains("portfolio") && combinedText.contains("valuation") {
            return .portfolioSummary
        } else if combinedText.contains("common stock") || combinedText.contains("equity") {
            return .equityHoldings
        } else if combinedText.contains("bond") || combinedText.contains("note") {
            return .bondHoldings
        } else if combinedText.contains("fx") || combinedText.contains("derivative") {
            return .derivativesData
        } else {
            return .paragraph
        }
    }
    
    private static func cropImage(_ cgImage: CGImage, to normalizedRect: CGRect) -> CGImage {
        let imageWidth = CGFloat(cgImage.width)
        let imageHeight = CGFloat(cgImage.height)
        
        let cropRect = CGRect(
            x: normalizedRect.minX * imageWidth,
            y: (1.0 - normalizedRect.maxY) * imageHeight,
            width: normalizedRect.width * imageWidth,
            height: normalizedRect.height * imageHeight
        )
        
        return cgImage.cropping(to: cropRect) ?? cgImage
    }
}
