//
//  ClassifierHomeView.swift
//  airbank-ocr-demo
//
//  Created by Rosemary Yang on 7/2/25.
//  Copyright © 2025 Marek Přidal. All rights reserved.
//


// ClassifierHomeView.swift
// Home screen for the PDF page classifier app

import SwiftUI

struct ClassifierHomeView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                NavigationLink("Start Classification", destination: PageClassifierView())
                    .padding()
                    .background(Color.blue.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .navigationTitle("PDF Classifier")
        }
    }
}