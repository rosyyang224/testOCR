//
//  ParserMethod.swift
//  airbank-ocr-demo
//
//  Created by Rosemary Yang on 7/9/25.
//  Copyright © 2025 Marek Přidal. All rights reserved.
//

import SwiftUI

struct CustomParserSelector: View {
    @Binding var selectedParser: ParserModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Parser")
                .font(AppTheme.captionFont)
                .foregroundColor(AppTheme.primaryText)

            HStack(spacing: 0) {
                ToggleButton(
                    title: "Docling",
                    isSelected: selectedParser == .docling,
                    position: .leading
                ) {
                    selectedParser = .docling
                }

                ToggleButton(
                    title: "PyPDF",
                    isSelected: selectedParser == .pypdf,
                    position: .trailing
                ) {
                    selectedParser = .pypdf
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.mediumGray, lineWidth: 1)
            )
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 8)
    }
}
