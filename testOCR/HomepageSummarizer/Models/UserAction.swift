//
//  UserAction.swift
//  airbank-ocr-demo
//
//  Created by Rosemary Yang on 7/10/25.
//  Copyright © 2025 Marek Přidal. All rights reserved.
//

import Foundation

struct RawUserData: Decodable {
    let user_id: String
    let session_id: String
    let events: [UserAction]
}

struct UserAction: Decodable {
    let timestamp: String
    let action: String
    let symbol: String?
    let page: String?
    let metric: String?
    let type: String?
    let section: String?
    let widget: String?
    let target: String?
    let label: String?
    let description: String?
    let timeframe: String?
    let criteria: String?
    let query: String?
    let direction: String?
    let method: String?
    let from: String?
    let to: String?
    let sort_by: String?

    var date: Date? {
        ISO8601DateFormatter().date(from: timestamp)
    }
}

struct UserFocusScore: Comparable {
    let topic: String
    let score: Double
    static func < (lhs: UserFocusScore, rhs: UserFocusScore) -> Bool {
        lhs.score < rhs.score
    }
}
