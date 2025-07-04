//
//  PassportMRZParser.swift
//  airbank-ocr-demo
//
//  Created by Rosemary Yang on 7/1/25.
//


import Foundation

/// Parses 2 or 3 MRZ lines and extracts structured passport fields
struct PassportMRZParser {

    struct MRZResult {
        let documentType: String
        let countryCode: String
        let surname: String
        let givenNames: String
        let passportNumber: String
        let nationality: String
        let dateOfBirth: String
        let sex: String
        let expirationDate: String
    }

    /// Parses TD3 MRZ (2 lines, 44 characters each)
    static func parse(lines: [String]) -> MRZResult? {
        guard lines.count == 2,
              lines[0].count == 44,
              lines[1].count == 44 else { return nil }

        let line1 = lines[0]
        let line2 = lines[1]

        let documentType = String(line1.prefix(2)).replacingOccurrences(of: "<", with: "")
        let countryCode = String(line1[line1.index(line1.startIndex, offsetBy: 2)..<line1.index(line1.startIndex, offsetBy: 5)])

        let nameSection = String(line1[line1.index(line1.startIndex, offsetBy: 5)...])
        let nameParts = nameSection.components(separatedBy: "<<")
        let surname = nameParts.first?.replacingOccurrences(of: "<", with: " ").trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let givenNames = nameParts.dropFirst().joined(separator: " ").replacingOccurrences(of: "<", with: " ").trimmingCharacters(in: .whitespacesAndNewlines)

        let passportNumber = String(line2.prefix(9)).replacingOccurrences(of: "<", with: "")
        let nationality = String(line2[line2.index(line2.startIndex, offsetBy: 10)..<line2.index(line2.startIndex, offsetBy: 13)])
        let birthDate = String(line2[line2.index(line2.startIndex, offsetBy: 13)..<line2.index(line2.startIndex, offsetBy: 19)])
        let sex = String(line2[line2.index(line2.startIndex, offsetBy: 20)])
        let expiryDate = String(line2[line2.index(line2.startIndex, offsetBy: 21)..<line2.index(line2.startIndex, offsetBy: 27)])

        return MRZResult(
            documentType: documentType,
            countryCode: countryCode,
            surname: surname,
            givenNames: givenNames,
            passportNumber: passportNumber,
            nationality: nationality,
            dateOfBirth: birthDate,
            sex: sex,
            expirationDate: expiryDate
        )
    }
}
