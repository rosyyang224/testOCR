// PDFSummarizerView.swift

import SwiftUI
import UniformTypeIdentifiers

struct PDFSummarizerView: View {
    @State private var summary: String = ""
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var selectedPDFURL: URL?
    @State private var useDocling: Bool = true
    @State private var showFilePicker = false

    var body: some View {
        VStack(spacing: 20) {
            Picker("Extraction Method", selection: $useDocling) {
                Text("Docling").tag(true)
                Text("PyPDF").tag(false)
            }
            .pickerStyle(.segmented)

            Button("Select PDF") {
                showFilePicker = true
            }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [.pdf],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let file = urls.first {
                        selectedPDFURL = file
                        Task { await process(file) }
                    }
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }

            if isProcessing {
                ProgressView("Processing...")
            }

            if let error = errorMessage {
                Text(error).foregroundColor(.red)
            }

            if !summary.isEmpty {
                ScrollView {
                    Text(summary)
                        .padding()
                }
            }
        }
        .padding()
    }

    func process(_ file: URL) async {
        isProcessing = true
        errorMessage = nil
        summary = ""

        do {
            let method: PDFTextExtractionMethod = useDocling ? .docling : .pypdf
            let extracted = try TextExtractor.extractText(from: file, using: method)

            let response = try await QwenSummarizer.summarize(text: extracted)
            summary = response
        } catch {
            errorMessage = error.localizedDescription
        }

        isProcessing = false
    }
}
