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
    @State private var selectedParser: ParserModel = .docling
    @State private var dragOver = false
    @State private var showResults = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    if !showResults {
                        mainCard
                        quickActionsSection
                    } else {
                        resultsCard
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(AppTheme.backgroundColor)
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

    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppTheme.primaryGradient)
                    .frame(width: 80, height: 80)
                    .shadow(color: AppTheme.primaryColor.opacity(0.3), radius: 8, x: 0, y: 4)
                Image(systemName: "doc.fill")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(.white)
            }
            .scaleEffect(isProcessing ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isProcessing)

            VStack(spacing: 4) {
                Text("PDF Summarizer")
                    .font(AppTheme.titleFont)
                    .foregroundColor(AppTheme.titleText)

                Text("Upload and summarize PDF documents instantly")
                    .font(AppTheme.bodyFont)
                    .foregroundColor(AppTheme.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var mainCard: some View {
        VStack(spacing: 24) {
            uploadArea
            settingsSection
            actionButton
        }
        .padding(24)
        .modifier(AppTheme.cardStyle())
    }

    private var uploadArea: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        dragOver ? AppTheme.primaryColor : AppTheme.mediumGray,
                        style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                    )
                    .background(dragOver ? AppTheme.primaryColor.opacity(0.05) : Color.clear)
                    .frame(height: 120)
                    .animation(.easeInOut(duration: 0.2), value: dragOver)

                VStack(spacing: 12) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 32))
                        .foregroundColor(AppTheme.primaryColor)
                    Text("Drop PDF here or tap below to select")
                        .font(AppTheme.bodyFont)
                        .foregroundColor(AppTheme.secondaryText)
                }
            }
        }
    }

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Summarization Settings")
                .font(AppTheme.subtitleFont)
                .foregroundColor(AppTheme.primaryText)

            CustomModelSelector(selectedModel: $selectedModel)

            CustomParserSelector(selectedParser: $selectedParser)
        }
    }

    private var actionButton: some View {
        Button(action: {
            showFilePicker = true
        }) {
            HStack(spacing: 12) {
                Image(systemName: "arrow.up.doc.fill")
                Text("Summarize PDF")
            }
        }
        .modifier(AppTheme.primaryButtonStyle())
        .disabled(isProcessing)
    }

    private var quickActionsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button(action: {
                    summary = ""
                    showResults = false
                }) {
                    Label("Clear", systemImage: "xmark.circle")
                }
                .modifier(AppTheme.secondaryButtonStyle())

                Button(action: {
                    showComparison = true
                }) {
                    Label("Compare", systemImage: "doc.text.magnifyingglass")
                }
                .modifier(AppTheme.secondaryButtonStyle())
            }
        }
    }

    private var resultsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Summary")
                .font(AppTheme.titleFont)
                .foregroundColor(AppTheme.titleText)

            Text(summary)
                .font(AppTheme.bodyFont)
                .foregroundColor(AppTheme.primaryText)
                .padding()
                .background(AppTheme.cardBackground)
                .cornerRadius(12)
        }
        .padding(24)
        .modifier(AppTheme.cardStyle())
    }

    private func process(_ url: URL) async {
        isProcessing = true
        summary = "Processing..."
        // Simulate summary result
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        summary = "Summary of uploaded PDF will appear here."
        isProcessing = false
        showResults = true
    }
}
