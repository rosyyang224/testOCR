import SwiftUI

struct JSONSummarizerView: View {
    @State private var rawJSON: String = mockJSON
    @State private var summary: String = "Summary will appear here."
    @State private var isProcessing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Raw JSON").font(.headline)

            TextEditor(text: $rawJSON)
                .frame(height: 180)
                .border(Color.gray)

            Button("Summarize") {
                Task {
                    isProcessing = true
                    do {
                        summary = try await FoundationJSONSummarizer.summarize(rawJSON)
                    } catch {
                        summary = "Error: \(error.localizedDescription)"
                    }
                    isProcessing = false
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue.opacity(0.8))
            .foregroundColor(.white)
            .cornerRadius(8)

            if isProcessing {
                ProgressView()
            }

            Text("Summary").font(.headline)

            ScrollView {
                Text(summary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical)
            }

            Spacer()
        }
        .padding()
    }
}
