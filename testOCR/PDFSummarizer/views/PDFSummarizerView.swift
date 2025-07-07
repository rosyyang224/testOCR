import SwiftUI
import UniformTypeIdentifiers

struct PDFSummarizerView: View {
    @State private var summary: String = ""
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var selectedPDFURL: URL?
    @State private var useDocling: Bool = true
    @State private var showFilePicker = false
    @State private var showComparison = false
    @State private var extractedPages: [String] = []
    @State private var pageImages: [CGImage] = []
    @State private var selectedModel: SummarizerModel = .foundation

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if selectedPDFURL == nil {
                    Picker("Extraction Method", selection: $useDocling) {
                        Text("Docling").tag(true)
                        Text("PyPDF").tag(false)
                    }
                    .pickerStyle(.segmented)

                    Picker("Model", selection: $selectedModel) {
                        ForEach(SummarizerModel.allCases) { model in
                            Text(model.rawValue).tag(model)
                        }
                    }
                    .pickerStyle(.segmented)

                    Button("Select PDF") {
                        showFilePicker = true
                    }
                } else {
                    Text("Extracted with \(useDocling ? "Docling" : "PyPDF")")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    Button("Scan Another PDF") {
                        selectedPDFURL = nil
                        summary = ""
                        extractedPages = []
                        pageImages = []
                        showComparison = false
                    }
                }

                if isProcessing {
                    ProgressView("Processing...")
                }

                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }

                if !summary.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Summary")
                            .font(.headline)

                        ScrollView {
                            Text(summary)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Text("Extracted Text")
                            .font(.headline)

                        ScrollView([.vertical, .horizontal]) {
                            Text(extractedPages.joined(separator: "\n"))
                                .font(.system(.body, design: .monospaced))
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding()
                }

                if showComparison {
                    NavigationLink("Compare Results", destination:
                        PDFComparisonView(
                            pageImages: pageImages,
                            pageTexts: extractedPages
                        )
                    )
                    .padding()
                }
            }
            .padding()
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
        }
    }
    
    func cleanHeadersAndFooters(from input: String) -> String {
        let lines = input.components(separatedBy: .newlines)

        let cleanedLines = lines.filter { line in
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return false }

            let patternsToExclude = [
                #"(?i)^.*morgan stanley.*$"#,
                #"(?i)^.*private wealth management.*$"#,
                #"(?i)^.*page \d+ of \d+.*$"#,
                #"(?i)^.*prr means product risk rating.*$"#,
                #"(?i)^.*commitment date reporting.*$"#,
                #"(?i)^.*cVVQ.*portfolio valuation.*$"#,
                #"(?i)^.*reporting currency.*usd.*$"#,
                #"(?i)^.*kindly see last page for disclosures.*$"#,

                #"(?i)^\s*internal use only\s*$"#,
                #"(?i)^\+\s+denotes upward revision of prr\s*$"#,
                #"(?i)^\*\s+denotes bank no longer risk rate this product\s*$"#,

                #"(?i)^cVVQ\s+[A-Z0-9\.]+$"#,
                #"(?i)^[A-Z]{5,}\s+[A-Z0-9\.]{10,}$"#,
                #"^\|?[-| ]{20,}\|?$"#
            ]


            for pattern in patternsToExclude {
                if let _ = trimmed.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                    return false
                }
            }

            return true
        }

        return cleanedLines.joined(separator: "\n")
    }


    func process(_ file: URL) async {
        isProcessing = true
        errorMessage = nil
        summary = ""
        showComparison = false

        do {
            let method: PDFTextExtractionMethod = useDocling ? .docling : .pypdf
            let chunks = try TextExtractor.extractTextPages(from: file, using: method)

            pageImages = PDFPageRenderer.renderPageCGImages(from: file)
            extractedPages = chunks

            let cleanedChunks = chunks.map { cleanHeadersAndFooters(from: $0) }

            switch selectedModel {
            case .foundation:
                summary = try await FoundationSummaryClient.summarize(cleanedChunks)
            case .qwen:
                let fullText = cleanedChunks.joined(separator: "\n\n")
                summary = try await QwenSummaryClient.summarize(fullText)
            }

            showComparison = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isProcessing = false
    }
}
