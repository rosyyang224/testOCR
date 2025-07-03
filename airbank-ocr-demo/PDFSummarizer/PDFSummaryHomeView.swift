//
//  PDFSummaryHomeView.swift
//  airbank-ocr-demo
//
//  Created by Rosemary Yang on 7/2/25.
//

import SwiftUI

struct PDFSummaryHomeView: View {
    var body: some View {
        NavigationView {
            List {
                NavigationLink("Summarize PDF", destination: PDFSummarizerView())
            }
            .navigationTitle("PDF Toolkit")
        }
    }
}

#Preview {
    PDFSummaryHomeView()
}
