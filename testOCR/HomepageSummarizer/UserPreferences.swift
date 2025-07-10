import Foundation
import CoreGraphics

struct AdaptiveConfig {
    let baseTopN: Int
    let minTopN: Int
    let maxTopN: Int
    let significanceThreshold: Double
    let diversityBoost: Double
    let engagementThreshold: Double

    static let financial = AdaptiveConfig(
        baseTopN: 1,
        minTopN: 1,
        maxTopN: 4,
        significanceThreshold: 0.15,
        diversityBoost: 0.25,
        engagementThreshold: 2.0
    )
}

class UserPreferences {
    private static var sessionHistory: [String: Int] = [:]
    private static var lastUpdateTime: Date = Date()
    private static let config = AdaptiveConfig.financial

    static func getUserFocusSummary(from logs: [UserAction], baseTopN: Int = 3, referenceDate: Date = Date()) -> [UserFocusScore] {
        let scores = computeScores(from: logs, referenceDate: referenceDate)
        let normalizedScores = normalizeScores(scores)
        let sortedScores = normalizedScores.sorted(by: >)

        let adaptiveN = calculateAdaptiveTopN(scores: sortedScores, baseTopN: baseTopN, logs: logs, referenceDate: referenceDate)
        let selectedScores = applyAdaptiveSelection(scores: sortedScores, targetCount: adaptiveN)

        updateSessionHistory(selectedScores)
        return selectedScores
    }

    private static func computeScores(from logs: [UserAction], referenceDate: Date) -> [UserFocusScore] {
        let subsectionToSection: [String: String] = [
            "Asset Class": "Allocations",
            "Currency": "Allocations",
            "Account": "Allocations",
            "Security Type": "Allocations",
            "Performance Chart": "Performance",
            "Year-to-Date Return": "Performance",
            "Last 6 Months": "Performance",
            "Performance History": "Performance",
            "Performance Breakdown": "Performance",
            "Transaction List": "Transactions",
            "Dividends Only": "Transactions",
            "Date Descending": "Transactions",
            "AAPL": "Holdings",
            "TSLA": "Holdings"
        ]

        var result: [String: Double] = [:]

        for log in logs {
            guard let date = log.date else { continue }

            let meaningless = ["login", "logout", "click_button", "click_widget", "search", "page_view", "hover"]
            if meaningless.contains(log.action) && log.section == nil && log.type == nil && log.metric == nil && log.symbol == nil {
                continue
            }

            let hoursAgo = max(0, referenceDate.timeIntervalSince(date) / 3600.0)
            let weight = 1.0 / (1.0 + hoursAgo)

            let fields = [log.symbol, log.metric, log.timeframe, log.section, log.type, log.target, log.criteria, log.description, log.query]

            var section: String? = nil
            var subsection: String? = nil

            for field in fields.compactMap({ $0 }) {
                if let mapped = subsectionToSection[field] {
                    section = mapped
                    subsection = field
                    break
                }
                for (key, mapped) in subsectionToSection {
                    if field.localizedCaseInsensitiveContains(key) {
                        section = mapped
                        subsection = key
                        break
                    }
                }
                if section != nil { break }
            }

            if section == nil {
                if log.action.contains("allocation") { section = "Allocations" }
                else if log.action.contains("transaction") { section = "Transactions" }
                else if log.action.contains("performance") { section = "Performance" }
                else if log.action.contains("holding") { section = "Holdings" }
                else if let page = log.page { section = page }
                else { continue }
            }

            let key = subsection != nil ? "\(section!) → \(subsection!)" : section!

            result[key, default: 0] += weight
        }
        
        let collapsed = result.map { UserFocusScore(topic: $0.key, score: $0.value) }

        return collapsed
    }


    private static func normalizeScores(_ scores: [UserFocusScore]) -> [UserFocusScore] {
        guard let max = scores.map({ $0.score }).max(), max > 0 else { return scores }
        return scores.map { UserFocusScore(topic: $0.topic, score: $0.score / max) }
    }

    private static func calculateAdaptiveTopN(scores: [UserFocusScore], baseTopN: Int, logs: [UserAction], referenceDate: Date) -> Int {
        let engagement = calculateEngagementFactor(logs: logs, referenceDate: referenceDate)
        let distribution = analyzeScoreDistribution(scores: scores)
        let diversity = analyzeSectionDiversity(scores: scores)
        let session = analyzeSessionContext(scores: scores)
        let temporal = analyzeTemporalPatterns(referenceDate: referenceDate)

        let adjustment = engagement * 0.3 + distribution * 0.25 + diversity * 0.2 + session * 0.15 + temporal * 0.1
        return max(config.minTopN, min(config.maxTopN, Int(Double(baseTopN) * adjustment)))
    }

    private static func calculateEngagementFactor(logs: [UserAction], referenceDate: Date) -> Double {
        let count = logs.filter {
            guard let date = $0.date else { return false }
            return referenceDate.timeIntervalSince(date) <= 86400
        }.count

        if Double(count) >= config.engagementThreshold * 3 { return 1.4 }
        if Double(count) >= config.engagementThreshold { return 1.2 }
        if Double(count) < config.engagementThreshold * 0.5 { return 0.8 }
        return 1.0
    }

    private static func analyzeScoreDistribution(scores: [UserFocusScore]) -> Double {
        guard scores.count > 1 else { return 1.0 }
        let top = scores[0].score
        let second = scores[1].score
        if top - second > top * 0.3 { return 0.8 }

        let values = scores.map { $0.score }
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        let stdDev = sqrt(variance)
        let coeffVar = stdDev / mean

        return coeffVar < 0.2 ? 1.3 : 1.0
    }

    private static func analyzeSectionDiversity(scores: [UserFocusScore]) -> Double {
        let sections = Set(scores.map { $0.topic.components(separatedBy: " → ").first ?? $0.topic })
        let diversity = Double(sections.count) / Double(scores.count)
        if diversity > 0.7 { return 1.2 }
        if diversity < 0.3 { return 0.9 }
        return 1.0
    }

    private static func analyzeSessionContext(scores: [UserFocusScore]) -> Double {
        let currentTopics = Set(scores.prefix(5).map { $0.topic })
        let overlap = currentTopics.intersection(Set(sessionHistory.keys))
        let ratio = Double(overlap.count) / Double(max(currentTopics.count, 1))
        if ratio > 0.8 { return 0.85 }
        if ratio < 0.2 { return 1.15 }
        return 1.0
    }

    private static func analyzeTemporalPatterns(referenceDate: Date) -> Double {
        let hour = Calendar.current.component(.hour, from: referenceDate)
        let weekday = Calendar.current.component(.weekday, from: referenceDate)
        if (2...6).contains(weekday) && (9...16).contains(hour) { return 1.1 }
        if (22...23).contains(hour) || (0...6).contains(hour) { return 0.9 }
        return 1.0
    }

    private static func applyAdaptiveSelection(scores: [UserFocusScore], targetCount: Int) -> [UserFocusScore] {
        guard scores.count > targetCount else { return scores }

        var selected = Array(scores.prefix(targetCount / 2).filter { $0.score >= config.significanceThreshold })

        var selectedTopics = Set(selected.map { $0.topic })

        let remainingScores = scores.filter { !selectedTopics.contains($0.topic) }
        
        for score in remainingScores {
            if selected.count >= targetCount { break }
            let topic = score.topic
            let isDuplicate = selectedTopics.contains(topic)
            let diversityBoost = isDuplicate ? 1.0 : (1.0 + config.diversityBoost)
            let adjusted = score.score * diversityBoost

            if adjusted >= config.significanceThreshold * 0.7 || !isDuplicate {
                selected.append(score)
                selectedTopics.insert(topic)
            }
        }

        return selected.sorted(by: >)
    }

    private static func updateSessionHistory(_ scores: [UserFocusScore]) {
        let now = Date()
        if now.timeIntervalSince(lastUpdateTime) > 3600 {
            sessionHistory = sessionHistory.mapValues { Int(Double($0) * 0.9) }.filter { $0.value > 0 }
        }
        for s in scores {
            sessionHistory[s.topic, default: 0] += 1
        }
        lastUpdateTime = now
    }
}
