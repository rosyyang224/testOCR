import SwiftUI
import UniformTypeIdentifiers

struct PDFSummarizerView: View {
    @State private var summary: StructuredSummary?
    @State private var isProcessing = false
    @State private var showingDocumentPicker = false
    @State private var errorMessage: String?
    @State private var processingProgress: Double = 0.0
    @State private var currentStep: String = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 12) {
                    Text("AI Document Analyzer")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Powered by Apple Vision + Foundation Models")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Button(action: {
                        showingDocumentPicker = true
                    }) {
                        HStack {
                            Image(systemName: "doc.fill.badge.plus")
                            Text("Import PDF and Analyze")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isProcessing)
                }
                .padding()

                // Progress section
                if isProcessing {
                    VStack(spacing: 12) {
                        ProgressView(value: processingProgress)
                            .progressViewStyle(LinearProgressViewStyle())
                        Text(currentStep)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Processing with on-device AI...")
                                .font(.subheadline)
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }

                // Error message
                if let error = errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.subheadline)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }

                // Results
                if let summary = summary {
                    VStack(spacing: 16) {
                        SummaryCard(
                            title: "Executive Summary",
                            content: summary.executiveSummary,
                            icon: "doc.text.fill",
                            color: .blue
                        )

                        if !summary.tableSummary.isEmpty && !summary.tableSummary.contains("No tables found") {
                            SummaryCard(
                                title: "Tables & Data Analysis",
                                content: summary.tableSummary,
                                icon: "tablecells.fill",
                                color: .green
                            )
                        }

                        if !summary.textSummary.isEmpty && !summary.textSummary.contains("No text content found") {
                            SummaryCard(
                                title: "Content Summary",
                                content: summary.textSummary,
                                icon: "text.alignleft",
                                color: .purple
                            )
                        }

                        if !summary.listSummary.isEmpty && !summary.listSummary.contains("No lists found") {
                            SummaryCard(
                                title: "Key Points & Lists",
                                content: summary.listSummary,
                                icon: "list.bullet",
                                color: .orange
                            )
                        }

                        SummaryCard(
                            title: "Document Structure",
                            content: summary.documentStructure,
                            icon: "doc.richtext",
                            color: .indigo
                        )
                    }
                }
            }
            .padding()
        }
        .navigationTitle("PDF Analyzer")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(
            isPresented: $showingDocumentPicker,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false
        ) { result in
            Task {
                await handleDocumentSelection(result)
            }
        }
    }

    private func handleDocumentSelection(_ result: Result<[URL], Error>) async {
        do {
            let urls = try result.get()
            guard let url = urls.first else { return }

            guard url.startAccessingSecurityScopedResource() else {
                await MainActor.run {
                    errorMessage = "Failed to access selected file"
                }
                return
            }

            defer { url.stopAccessingSecurityScopedResource() }

            await analyzeDocument(from: url)
        } catch {
            await MainActor.run {
                errorMessage = "Failed to select PDF: \(error.localizedDescription)"
            }
        }
    }

    private func analyzeDocument(from url: URL) async {
        await MainActor.run {
            isProcessing = true
            summary = nil
            errorMessage = nil
            processingProgress = 0.0
            currentStep = "Initializing document processing..."
        }

        do {
            await updateProgress(0.2, "Extracting document structure with Vision...")
            let sections = await DocumentProcessor.extractStructuredContent(from: url)

            if sections.isEmpty {
                await MainActor.run {
                    errorMessage = "No content could be extracted from the PDF"
                    isProcessing = false
                }
                return
            }

            await updateProgress(0.6, "Summarizing extracted content with Foundation Models...")
            let result = try await FoundationSummaryClient.summarizeStructuredContent(sections)

            await MainActor.run {
                summary = result
                isProcessing = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Analysis failed: \(error.localizedDescription)"
                isProcessing = false
            }
        }
    }

    private func updateProgress(_ progress: Double, _ step: String) async {
        await MainActor.run {
            processingProgress = progress
            currentStep = step
        }
    }
}
