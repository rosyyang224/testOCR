import Foundation

enum DateParser {
    /// Parses ISO date first (e.g. "2024-09-01"), then tries natural language (e.g. "August", "last year")
    static func parse(_ raw: String) -> Date? {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withFullDate]

        if let exact = isoFormatter.date(from: raw) {
            return exact
        }

        // Fallback: natural language (e.g. "August 2024", "last September")
        return parseNaturalLanguage(raw)
    }

    /// Uses NSDataDetector to pull out date from fuzzy natural language
    private static func parseNaturalLanguage(_ input: String, reference: Date = Date()) -> Date? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) else {
            return nil
        }
        let matches = detector.matches(in: input, range: NSRange(location: 0, length: input.utf16.count))
        return matches.first?.date
    }

    /// Get granularity of user input: year/month/day depending on format
    static func detectGranularity(_ input: String) -> Calendar.Component {
        if input.range(of: #"^\d{4}-\d{2}-\d{2}$"#, options: .regularExpression) != nil {
            return .day
        } else if input.range(of: #"^\d{4}-\d{2}$"#, options: .regularExpression) != nil {
            return .month
        } else if input.range(of: #"^\d{4}$"#, options: .regularExpression) != nil {
            return .year
        } else {
            return .month // default for fuzzy language like "August"
        }
    }
}
