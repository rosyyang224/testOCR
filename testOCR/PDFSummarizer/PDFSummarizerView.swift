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
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if selectedPDFURL == nil {
                    Picker("Extraction Method", selection: $useDocling) {
                        Text("Docling").tag(true)
                        Text("PyPDF").tag(false)
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
                    ScrollView([.horizontal, .vertical]) {
                        Text(summary)
                            .font(.system(.body, design: .monospaced))
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(10)
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
            
            let fullText = chunks.joined(separator: "\n")
            let response = try await QwenSummarizer.summarize(text: fullText)
            
            summary = response
            showComparison = true
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isProcessing = false
    }
}
