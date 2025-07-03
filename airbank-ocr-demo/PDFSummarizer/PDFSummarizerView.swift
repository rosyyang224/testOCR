// PDFSummarizerView.swift
import SwiftUI

struct PDFSummarizerView: View {
    @State private var summaries: [String] = []
    @State private var overallSummary: String = ""
    @State private var isProcessing = false

    var body: some View {
        VStack(spacing: 16) {
            Button("📎 Import PDF and Summarize") {
                Task { await summarizePDF() }
            }
            .disabled(isProcessing)

            if isProcessing {
                ProgressView("Processing...")
            }

            List(summaries.indices, id: \ .self) { idx in
                Text("Section \(idx + 1): \(summaries[idx])")
            }

            if !overallSummary.isEmpty {
                Text("📌 Overall Summary")
                    .font(.headline)
                    .padding(.top)
                Text(overallSummary)
            }
        }
        .padding()
        .navigationTitle("Summarize PDF")
    }

    func summarizePDF() async {
        isProcessing = true
        summaries = []
        overallSummary = ""

        do {
            guard let url = try await PDFSelector.pick() else {
                isProcessing = false
                return
            }

            let sections = await OCRProcessor.extractTextAndTables(from: url)
            let result = await PageClassifier.summarizeSections(sections)

            summaries = result.summaries
            overallSummary = result.overall
        } catch {
            print("PDF processing failed: \(error)")
        }

        isProcessing = false
    }
}
