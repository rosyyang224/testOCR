//
//  PDFSummarizerView.swift
//  airbank-ocr-demo
//
//  Created by Rosemary Yang on 7/3/25.
//  Copyright © 2025 Marek Přidal. All rights reserved.
//
import SwiftUI
import UniformTypeIdentifiers

struct PDFSummarizerView: View {
    @State private var documentAnalysis: DocumentAnalysis?
    @State private var isProcessing = false
    @State private var showingDocumentPicker = false
    @State private var errorMessage: String?
    @State private var processingProgress: Double = 0.0
    @State private var currentStep: String = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header Section
                VStack(spacing: 12) {
                    Text("AI Document Analyzer")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Powered by Apple Vision + Foundation Models")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        showingDocumentPicker = true
                    }) {
                        HStack {
                            Image(systemName: "doc.fill.badge.plus")
                            Text("Import PDF and Analyze")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isProcessing)
                }
                .padding()
                
                // Processing Section
                if isProcessing {
                    VStack(spacing: 12) {
                        ProgressView(value: processingProgress, total: 1.0)
                            .progressViewStyle(LinearProgressViewStyle())
                        
                        Text(currentStep)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Processing with on-device AI...")
                                .font(.subheadline)
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
                
                // Error Section
                if let error = errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.subheadline)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Results Section
                if let analysis = documentAnalysis {
                    VStack(spacing: 16) {
                        // Document Overview Card
                        DocumentOverviewCard(analysis: analysis)
                        
                        // Executive Summary Card
                        SummaryCard(
                            title: "Executive Summary",
                            content: analysis.structuredSummary.executiveSummary,
                            icon: "doc.text.fill",
                            color: .blue
                        )
                        
                        // Detailed Analysis Sections
                        if !analysis.structuredSummary.tableSummary.isEmpty &&
                           !analysis.structuredSummary.tableSummary.contains("No tables found") {
                            SummaryCard(
                                title: "Tables & Data Analysis",
                                content: analysis.structuredSummary.tableSummary,
                                icon: "tablecells.fill",
                                color: .green
                            )
                        }
                        
                        if !analysis.structuredSummary.textSummary.isEmpty &&
                           !analysis.structuredSummary.textSummary.contains("No text content found") {
                            SummaryCard(
                                title: "Content Summary",
                                content: analysis.structuredSummary.textSummary,
                                icon: "text.alignleft",
                                color: .purple
                            )
                        }
                        
                        if !analysis.structuredSummary.listSummary.isEmpty &&
                           !analysis.structuredSummary.listSummary.contains("No lists found") {
                            SummaryCard(
                                title: "Key Points & Lists",
                                content: analysis.structuredSummary.listSummary,
                                icon: "list.bullet",
                                color: .orange
                            )
                        }
                        
                        // Document Structure
                        SummaryCard(
                            title: "Document Structure",
                            content: analysis.structuredSummary.documentStructure,
                            icon: "doc.richtext",
                            color: .indigo
                        )
                    }
                }
            }
            .padding()
        }
        .navigationTitle("PDF Analyzer")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(
            isPresented: $showingDocumentPicker,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false
        ) { result in
            Task {
                await handleDocumentSelection(result)
            }
        }
    }

    private func handleDocumentSelection(_ result: Result<[URL], Error>) async {
        do {
            let urls = try result.get()
            guard let url = urls.first else { return }
            
            guard url.startAccessingSecurityScopedResource() else {
                await MainActor.run {
                    errorMessage = "Failed to access selected file"
                }
                return
            }
            
            defer {
                url.stopAccessingSecurityScopedResource()
            }
            
            await analyzeDocument(from: url)
        } catch {
            await MainActor.run {
                errorMessage = "Failed to select PDF: \(error.localizedDescription)"
            }
        }
    }

    private func analyzeDocument(from url: URL) async {
        await MainActor.run {
            isProcessing = true
            documentAnalysis = nil
            errorMessage = nil
            processingProgress = 0.0
            currentStep = "Initializing document processing..."
        }

        do {
            // Step 1: Extract structured content using Vision
            await updateProgress(0.2, "Extracting document structure with Vision...")
            let sections = await DocumentProcessor.extractStructuredContent(from: url)
            
            if sections.isEmpty {
                await MainActor.run {
                    errorMessage = "No content could be extracted from the PDF"
                    isProcessing = false
                }
