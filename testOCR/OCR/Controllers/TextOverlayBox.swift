//
//  TextOverlayBox.swift
//  airbank-ocr-demo
//
//  Created by Rosemary Yang on 7/3/25.
//  Copyright © 2025 Marek Přidal. All rights reserved.
//


import SwiftUI
import Vision

struct TextOverlayBox: View {
    var observations: [VNRecognizedTextObservation]

    var body: some View {
        GeometryReader { geometry in
            ForEach(observations.indices, id: \.self) { index in
                let rect = convert(observations[index].boundingBox, in: geometry.size)

                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.yellow, lineWidth: 2)
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)
            }
        }
    }

    private func convert(_ boundingBox: CGRect, in size: CGSize) -> CGRect {
        CGRect(
            x: boundingBox.origin.x * size.width,
            y: (1 - boundingBox.origin.y - boundingBox.height) * size.height,
            width: boundingBox.width * size.width,
            height: boundingBox.height * size.height
        )
    }
}
