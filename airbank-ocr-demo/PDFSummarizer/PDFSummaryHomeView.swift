//
//  MainHomeView.swift
//  airbank-ocr-demo
//
//  Created by Rosemary Yang on 7/2/25.
//  Copyright © 2025 Marek Přidal. All rights reserved.
//


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