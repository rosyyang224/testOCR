// PageClassifierView.swift
import SwiftUI
import PDFKit
import Vision

struct PageClassifierView: View {
    @State private var classifications: [Int: String] = [:]
    @State private var isProcessing = false
    @State private var sections: [ReportSection] = []

    var body: some View {
        VStack(spacing: 16) {
            Button("Import PDF and Classify") {
                Task {
                    await classifyPDF()
                }
            }.disabled(isProcessing)

            if isProcessing {
                ProgressView("Classifying...")
            }

            List(sections) { section in
                Text("\(section.label): p\(section.pageRange.lowerBound + 1)-\(section.pageRange.upperBound + 1)")
            }
        }
        .padding()
        .navigationTitle("Classify Pages")
    }

    func classifyPDF() async {
        guard let url = try? await PDFSelector.pick() else { return }
        guard let doc = PDFDocument(url: url) else { return }

        isProcessing = true
        classifications = [:]
        sections = []

        var tempSections: [ReportSection] = []
        var lastType: String? = nil
        var lastHeader: String? = nil
        var startPage = 0

        for i in 0..<doc.pageCount {
            guard let page = doc.page(at: i) else { continue }
            let img = page.thumbnail(of: CGSize(width: 1000, height: 1414), for: .mediaBox)
            let obs = await OCRProcessor.extractRawObservations(from: img)
            let (type, header) = PageClassifier.classify(obs)

            if type != lastType || (type == "chart" && header != lastHeader) {
                if let last = lastType {
                    tempSections.append(ReportSection(id: UUID(), label: lastType! + (lastHeader != nil ? ": \(lastHeader!)" : ""), pageRange: startPage..<(i)))
                }
                startPage = i
                lastType = type
                lastHeader = header
            }
        }
        if let last = lastType {
            tempSections.append(ReportSection(id: UUID(), label: lastType! + (lastHeader != nil ? ": \(lastHeader!)" : ""), pageRange: startPage..<doc.pageCount))
        }

        sections = tempSections
        isProcessing = false
    }
}
