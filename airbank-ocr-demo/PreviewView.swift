//
//  PreviewView.swift
//  VisionDetection
//
//  Created by Wei Chieh Tseng on 09/06/2017.
//  Copyright © 2017 Willjay. All rights reserved.
//

import UIKit
import Vision

class PreviewView: UIView {
    private var maskLayer = [CAShapeLayer]()

    func drawRect(textObservation: VNRecognizedTextObservation) {
        let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -frame.height)
        let translate = CGAffineTransform.identity.scaledBy(x: frame.width, y: frame.height)
        let textBounds = textObservation.boundingBox.applying(translate).applying(transform)

        let mask = CAShapeLayer()
        mask.frame = textBounds
        mask.cornerRadius = 10
        mask.opacity = 0.75
        mask.borderColor = UIColor.yellow.cgColor
        mask.borderWidth = 2.0

        maskLayer.append(mask)
        layer.insertSublayer(mask, at: 1)

        let label = UILabel(frame: mask.frame)
        label.font = .systemFont(ofSize: 5)
        label.textColor = .systemRed
        if let topResult = textObservation.topCandidates(1).first {
            label.text = topResult.string
        }
        addSubview(label)
    }

    func removeMask() {
        for mask in maskLayer {
            mask.removeFromSuperlayer()
        }
        subviews.forEach({ $0.removeFromSuperview() })
        maskLayer.removeAll()
    }
}
