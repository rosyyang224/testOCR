// MainHomeView.swift
// Top-level switchboard for 4-prong OCR summarizer app

import SwiftUI

struct MainHomeView: View {
    var body: some View {
        TabView {
            // Prong 1: OCR Scan Tool
            HomeViewControllerWrapper()
                .tabItem {
                    Label("OCR", systemImage: "viewfinder")
                }

            // Prong 2: PDF Page Classifier (PDFSummary)
            PageClassifierView()
                .tabItem {
                    Label("Classifier", systemImage: "doc.text.magnifyingglass")
                }

            // Prong 3: PDF Summary Placeholder (TO BUILD)
            Text("PDF Summary Prong")
                .tabItem {
                    Label("Summary", systemImage: "doc.plaintext")
                }

            // Prong 4: Dynamic Query Placeholder (TO BUILD)
            Text("Query Interface Prong")
                .tabItem {
                    Label("Query", systemImage: "questionmark.circle")
                }
        }
    }
}

struct HomeViewControllerWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        return HomeViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
