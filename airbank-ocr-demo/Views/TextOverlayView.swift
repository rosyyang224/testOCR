//
//  TextOverlayView.swift
//  airbank-ocr-demo
//
//  Created by Rosemary Yang on 7/1/25.
//  Copyright © 2025 Marek Přidal. All rights reserved.
//


import UIKit
import Vision

final class TextOverlayView: UIView {
    private var layers = [CAShapeLayer]()

    /// Draws bounding box for a recognized text observation
    func drawBoundingBox(for observation: VNRecognizedTextObservation) {
        let imageRect = bounds
        let rect = CGRect(
            x: observation.boundingBox.minX * imageRect.width,
            y: (1 - observation.boundingBox.maxY) * imageRect.height,
            width: observation.boundingBox.width * imageRect.width,
            height: observation.boundingBox.height * imageRect.height
        )

        let shape = CAShapeLayer()
        shape.frame = rect
        shape.borderColor = UIColor.yellow.cgColor
        shape.borderWidth = 2
        shape.opacity = 0.75
        shape.cornerRadius = 6
        layer.addSublayer(shape)
        layers.append(shape)

        if let text = observation.topCandidates(1).first?.string {
            let label = UILabel(frame: rect)
            label.text = text
            label.textColor = .red
            label.font = .systemFont(ofSize: 5)
            addSubview(label)
        }
    }

    /// Draws a bounding box from a normalized CGRect (e.g., from a rectangle detector)
    func drawBoundingBox(for normalizedRect: CGRect, color: UIColor = .green, lineWidth: CGFloat = 2.0) {
        let rect = CGRect(
            x: normalizedRect.origin.x * bounds.width,
            y: (1 - normalizedRect.origin.y - normalizedRect.height) * bounds.height,
            width: normalizedRect.width * bounds.width,
            height: normalizedRect.height * bounds.height
        )

        let shape = CAShapeLayer()
        shape.frame = rect
        shape.borderColor = color.cgColor
        shape.borderWidth = lineWidth
        shape.opacity = 0.8
        shape.cornerRadius = 8
        layer.addSublayer(shape)
        layers.append(shape)
    }

    func clear() {
        layers.forEach { $0.removeFromSuperlayer() }
        layers.removeAll()
        subviews.forEach { $0.removeFromSuperview() }
    }
}
