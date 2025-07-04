import SwiftUI

struct MainHomeView: View {
    var body: some View {
        TabView {
            // Prong 1: OCR Scan Tool
            HomeOCRView()
                .tabItem {
                    Label("OCR", systemImage: "viewfinder")
                }

            // Prong 3: PDF Summary
            PDFSummarizerView()
                .tabItem {
                    Label("Summary", systemImage: "doc.plaintext")
                }

            // Prong 4: Dynamic Query Interface (placeholder)
            QueryInterfaceView()
                .tabItem {
                    Label("Query", systemImage: "questionmark.circle")
                }
        }
    }
}

struct HomeOCRView: View {
    var body: some View {
        ScrollView {
            HomeMainCardView {
                // Add action here if needed
                print("Scan tapped")
            }
        }
        .navigationTitle("Scan Passport")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

struct QueryInterfaceView: View {
    var body: some View {
        VStack {
            Text("Query Interface Coming Soon")
                .font(.title)
                .padding()
        }
    }
}
