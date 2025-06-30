//
//  TextObservationRepresentable.swift
//  airbank-ocr-demo
//
//  Created by Rosemary Yang on 6/30/25.
//  Copyright © 2025 Marek Přidal. All rights reserved.
//


import Foundation
import Vision
import CoreGraphics

protocol TextObservationRepresentable {
    var text: String { get }
    var boundingBox: CGRect { get }
}

extension VNRecognizedTextObservation: TextObservationRepresentable {
    var text: String {
        return topCandidates(1).first?.string ?? ""
    }
}
