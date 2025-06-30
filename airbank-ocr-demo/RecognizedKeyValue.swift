//
//  RecognizedKeyValue.swift
//  airbank-ocr-demo
//
//  Created by Marek Přidal on 20/11/2019.
//  Copyright © 2019 Marek Přidal. All rights reserved.
//

import Foundation
import Vision

struct RecognizedKeyValue {
    enum Alignment {
        case vertical
        case horizontal
    }

    enum DocumentElement: String, CaseIterable {
        case surname = "SURNAME"
        case givenNames = "GIVEN NAMES"
        case dateOfBirth = "DATE OF BIRTH"
        case documentNo = "DOCUMENT NO."
        case placeOfBirth = "PLACE OF BIRTH"
        case nationality = "NATIONALITY"
        case dateOfIssue = "DATE OF ISSUE"
        case dateOfExpiry = "DATE OF EXPIRY"
        case sex = "SEX"
        
        static var allKeywords: Set<String> {
            Set(Self.allCases.flatMap { $0.keywords.map { $0.uppercased() } })
        }

        var keywords: [String] {
            switch self {
            case .surname:
                return ["SURNAME", "FAMILY NAME", "LAST NAME"]
            case .givenNames:
                return ["GIVEN NAME", "GIVEN NAMES", "FIRST NAME"]
            case .dateOfBirth:
                return ["DATE OF BIRTH", "BIRTHDATE", "DOB"]
            case .documentNo:
                return ["DOCUMENT NO.", "DOCUMENT NUMBER", "DOC NO", "PASSPORT NO", "PASSPORT NUMBER"]
            case .placeOfBirth:
                return ["PLACE OF BIRTH", "BIRTHPLACE"]
            case .nationality:
                return ["NATIONALITY", "CITIZENSHIP"]
            case .dateOfIssue:
                return ["DATE OF ISSUE", "ISSUE DATE"]
            case .dateOfExpiry:
                return ["DATE OF EXPIRY", "EXPIRATION DATE", "EXPIRY DATE", "DATE OF EXP"]
            case .sex:
                return ["SEX", "GENDER"]
            }
        }
    }
    
    let key: String
    let keyTextObservation: VNRecognizedTextObservation
    
    var keyPosition: VNRectangleObservation? {
        try? keyTextObservation.topCandidates(10).first(where: { $0.string == key })?.boundingBox(for: Range<String.Index>.init(uncheckedBounds: (key.startIndex, key.endIndex)))
    }
    var alignment: Alignment {
        key.contains("SURNAME") || key.contains("GIVEN NAMES") || key.contains("DOCUMENT NO.") ? .horizontal : .vertical
    }
    var documentElement: DocumentElement? {
        DocumentElement(rawValue: key)
    }

    var value: String?
    var valueTextObservation: VNRecognizedTextObservation?
}
