//
//  PageClassifierView.swift
//  airbank-ocr-demo
//
//  Created by Rosemary Yang on 7/2/25.
//  Copyright © 2025 Marek Přidal. All rights reserved.
//


// PageClassifierView.swift
// Classifies PDF pages as 'chart' or 'text'

import SwiftUI
import Vision
import PDFKit
import UniformTypeIdentifiers
import UIKit

struct PageClassifierView: View {
    @State private var classifications: [Int: String] = [:]
    @State private var isProcessing = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 16) {
            Button("Import PDF and Classify") {
                importPDF()
            }
            .disabled(isProcessing)

            if isProcessing {
                ProgressView("Processing...")
            }

            if let errorMessage = errorMessage {
                Text(errorMessage).foregroundColor(.red)
            }

            List(classifications.sorted(by: { $0.key < $1.key }), id: \.key) { entry in
                Text("Page \(entry.key + 1): \(entry.value.uppercased())")
            }
        }
        .padding()
        .navigationTitle("Classify Pages")
    }

    func importPDF() {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.pdf])
        picker.allowsMultipleSelection = false
        picker.delegate = DocumentPickerDelegate(onPick: classifyPDF)

        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(picker, animated: true)
        }
    }

    func classifyPDF(from url: URL) {
        guard let doc = PDFDocument(url: url) else {
            errorMessage = "Failed to open PDF."
            return
        }

        isProcessing = true
        classifications = [:]
        errorMessage = nil

        Task {
            for i in 0..<doc.pageCount {
                if let page = doc.page(at: i) {
                    let img = page.thumbnail(of: CGSize(width: 1000, height: 1414), for: .mediaBox)
                    let lines = await OCRProcessor.extractText(from: img)
                    let tag = PageClassifier.classify(lines)
                    DispatchQueue.main.async {
                        classifications[i] = tag
                    }
                }
            }
            isProcessing = false
        }
    }
}
