// PageClassifierView.swift
// Classifies PDF pages as 'chart' or 'text' using layout heuristics

import SwiftUI
import Vision
import PDFKit
import UniformTypeIdentifiers
import UIKit

struct PageClassifierView: View {
    @State private var classifications: [Int: String] = [:]
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @StateObject private var pickerDelegate = DocumentPickerDelegate()

    var body: some View {
        VStack(spacing: 16) {
            Button("Import PDF and Classify") {
                importPDF()
            }
            .disabled(isProcessing)

            if isProcessing {
                ProgressView("Processing...")
            }

            if let errorMessage = errorMessage {
                Text(errorMessage).foregroundColor(.red)
            }

            List(classifications.sorted(by: { $0.key < $1.key }), id: \.key) { entry in
                Text("Page \(entry.key + 1): \(entry.value.uppercased())")
            }
        }
        .padding()
        .navigationTitle("Classify Pages")
    }

    func importPDF() {
        pickerDelegate.onPick = classifyPDF
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.pdf])
        picker.allowsMultipleSelection = false
        picker.delegate = pickerDelegate

        if let root = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?.rootViewController {
            root.present(picker, animated: true)
        } else {
            errorMessage = "Could not find a root view controller."
        }
    }

    func classifyPDF(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            errorMessage = "Permission denied to access file."
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }

        guard let doc = PDFDocument(url: url) else {
            errorMessage = "Failed to open PDF."
            return
        }

        isProcessing = true
        classifications = [:]
        errorMessage = nil

        Task {
            for i in 0..<doc.pageCount {
                print("=====Page\(i+1)======")
                if let page = doc.page(at: i) {
                    let img = page.thumbnail(of: CGSize(width: 1000, height: 1414), for: .mediaBox)
                    let observations = await OCRProcessor.extractRawObservations(from: img)
                    let tag = classifyHeuristically(from: observations)
                    DispatchQueue.main.async {
                        classifications[i] = tag
                    }
                }
            }
            isProcessing = false
        }
    }

    func classifyHeuristically(from observations: [VNRecognizedTextObservation]) -> String {
        let groupedByY = Dictionary(grouping: observations) {
            round($0.boundingBox.midY * 100) / 100
        }

        var chunkCountFrequency: [Int: Int] = [:]
        var headerLine: [VNRecognizedTextObservation] = []
        var maxChunkLineCount = 0

        print("🧠 Debug: Analyzing page layout")

        for (y, lineGroup) in groupedByY.sorted(by: { $0.key > $1.key }) {
            let sorted = lineGroup.sorted { $0.boundingBox.minX < $1.boundingBox.minX }

            var count = 0
            var lastMaxX: CGFloat = 0

            for obs in sorted {
                if obs.boundingBox.minX > lastMaxX + 0.02 {
                    count += 1
                    lastMaxX = obs.boundingBox.maxX
                }
            }

            if count >= 3 {
                chunkCountFrequency[count, default: 0] += 1

                if count > maxChunkLineCount {
                    maxChunkLineCount = count
                    headerLine = sorted
                }
            }
        }

        print("📊 Chunk count frequency:")
        for (chunkCount, freq) in chunkCountFrequency.sorted(by: { $0.key < $1.key }) {
            print("  - \(chunkCount) chunks: \(freq) line(s)")
        }

        let isChart = chunkCountFrequency.contains { (key, value) in
            key >= 3 && value >= 2
        }

        if isChart {
            let headerText = headerLine.compactMap { $0.topCandidates(1).first?.string }.joined(separator: " | ")
            print("📊 Detected chart header: \(headerText)")
        }

        print("✅ Classification: \(isChart ? "CHART" : "TEXT")\n")
        return isChart ? "chart" : "text"
    }

}
