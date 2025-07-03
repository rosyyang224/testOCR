//
//  DocumentRenderer.swift
//  airbank-ocr-demo
//
//  Created by Rosemary Yang on 7/3/25.
//  Copyright © 2025 Marek Přidal. All rights reserved.
//

enum DocumentRenderer {
    static func renderOverlay(on image: UIImage, textBoxes: [VNRecognizedTextObservation], tableBoxes: [CGRect]) -> UIImage {
        let size = image.size
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        image.draw(at: .zero)

        let context = UIGraphicsGetCurrentContext()!

        context.setLineWidth(2)

        context.setStrokeColor(UIColor.red.cgColor)
        for obs in textBoxes {
            context.stroke(convert(obs.boundingBox, in: size))
        }

        context.setStrokeColor(UIColor.blue.cgColor)
        for box in tableBoxes {
            context.stroke(convert(box, in: size))
        }

        let result = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return result
    }

    private static func convert(_ rect: CGRect, in size: CGSize) -> CGRect {
        CGRect(
            x: rect.origin.x * size.width,
            y: (1 - rect.origin.y - rect.height) * size.height,
            width: rect.width * size.width,
            height: rect.height * size.height
        )
    }
}
