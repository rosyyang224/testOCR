//
//  FoundationJSONSummarizer.swift
//  airbank-ocr-demo
//
//  Created by Rosemary Yang on 7/9/25.
//  Copyright © 2025 Marek Přidal. All rights reserved.
//


import Foundation
import FoundationModels

@Observable
class FoundationJSONSummarizer {
    private var model: LanguageModel?

    init() {
        Task {
            self.model = try? await LanguageModel()
        }
    }

    func summarize(jsonString: String) async -> String {
        guard let model else { return "Model not ready." }
        
        let prompt = """
        Summarize the following JSON data:
        \(jsonString)
        """
        
        do {
            let result = try await model.complete(prompt: prompt)
            return result
        } catch {
            return "Error: \(error.localizedDescription)"
        }
    }
}
