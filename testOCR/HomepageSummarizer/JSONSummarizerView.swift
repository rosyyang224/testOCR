import SwiftUI

struct JSONSummarizerView: View {
    @State private var rawJSON: String = "{}"
    @State private var summary: String = "Summary will appear here."
    @State private var isProcessing = false
    @State private var summarizer = FoundationJSONSummarizer()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Raw JSON")
                .font(.headline)
            TextEditor(text: $rawJSON)
                .frame(height: 150)
                .border(Color.gray)

            Button("Summarize") {
                Task {
                    isProcessing = true
                    summary = await summarizer.summarize(jsonString: rawJSON)
                    isProcessing = false
                }
            }
            .padding()
            .background(Color.blue.opacity(0.8))
            .foregroundColor(.white)
            .cornerRadius(8)

            if isProcessing {
                ProgressView()
            }

            Text("Summary")
                .font(.headline)
            ScrollView {
                Text(summary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer()
        }
        .padding()
        .onAppear {
            // Optional: listen for JSON pushed from Capacitor
            NotificationCenter.default.addObserver(forName: .receivedJSON, object: nil, queue: .main) { notification in
                if let jsonString = notification.object as? String {
                    self.rawJSON = jsonString
                }
            }
        }
    }
}

extension Notification.Name {
    static let receivedJSON = Notification.Name("ReceivedJSONFromJS")
}
