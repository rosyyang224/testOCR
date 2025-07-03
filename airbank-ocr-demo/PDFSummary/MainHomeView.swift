// MainHomeView.swift
import SwiftUI

struct MainHomeView: View {
    var body: some View {
        NavigationView {
            List {
                NavigationLink("📄 Classify Pages", destination: PageClassifierView())
                NavigationLink("🧠 Summarize Sections", destination: SectionSummarizerView())
            }
            .navigationTitle("Report Toolkit")
        }
    }
}

#Preview {
    MainHomeView()
}