//
//  RecognizedKeyValue.swift
//  airbank-ocr-demo
//
//  Created by Rosemary Yang on 7/2/25.
//


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

        static var allKeywords: Set<String> {
            Set(allCases.flatMap { $0.keywords.map { $0.uppercased() } })
        }
    }

    let key: String
    let keyTextObservation: VNRecognizedTextObservation?
    var value: String?
    let valueTextObservation: VNRecognizedTextObservation?

    var alignment: Alignment {
        switch key.uppercased() {
        case "SURNAME", "GIVEN NAMES", "DOCUMENT NO.":
            return .horizontal
        default:
            return .vertical
        }
    }

    var documentElement: DocumentElement? {
        DocumentElement(rawValue: key)
    }
    
    init(key: String, value: String?, keyTextObservation: VNRecognizedTextObservation? = nil, valueTextObservation: VNRecognizedTextObservation? = nil) {
        self.key = key
        self.value = value
        self.keyTextObservation = keyTextObservation
        self.valueTextObservation = valueTextObservation
    }

}

struct RecognizedWord {
    let text: String
    let boundingBox: CGRect
}
