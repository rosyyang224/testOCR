import SwiftUI

struct MainHomeView: View {
    var body: some View {
        TabView {
            // Prong 1: OCR Scan Tool
            HomeScreenView()
                .tabItem {
                    Label("OCR", systemImage: "viewfinder")
                }

            // Prong 2: PDF Summary
            PDFSummarizerView()
                .tabItem {
                    Label("PDF", systemImage: "doc.plaintext")
                }
            
            JSONSummarizerView()
                .tabItem {
                    Label("Homepage Summary", systemImage: "doc.plaintext")
                }

            // Prong 4: Dynamic Query Interface (placeholder)
            DynamicQueryView()
                .tabItem {
                    Label("Query", systemImage: "questionmark.circle")
                }
        }
    }
}
