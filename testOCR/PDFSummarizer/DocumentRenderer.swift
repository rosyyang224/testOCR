import SwiftUI
import Vision
import CoreGraphics
import CoreImage

enum DocumentRenderer {
    static func renderOverlay(on baseCGImage: CGImage, textBoxes: [VNRecognizedTextObservation], tableBoxes: [CGRect]) -> CGImage? {
        let size = CGSize(width: baseCGImage.width, height: baseCGImage.height)

        // Create CGContext
        guard let colorSpace = baseCGImage.colorSpace,
              let context = CGContext(
                data: nil,
                width: Int(size.width),
                height: Int(size.height),
                bitsPerComponent: baseCGImage.bitsPerComponent,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else {
            return nil
        }

        // Draw base image
        context.draw(baseCGImage, in: CGRect(origin: .zero, size: size))

        // Set drawing styles
        context.setLineWidth(2.0)

        // Red: Text Boxes
        context.setStrokeColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1))
        for obs in textBoxes {
            let converted = convert(obs.boundingBox, in: size)
            context.stroke(converted)
        }

        // Blue: Table Boxes
        context.setStrokeColor(CGColor(red: 0, green: 0, blue: 1, alpha: 1))
        for box in tableBoxes {
            let converted = convert(box, in: size)
            context.stroke(converted)
        }

        return context.makeImage()
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
