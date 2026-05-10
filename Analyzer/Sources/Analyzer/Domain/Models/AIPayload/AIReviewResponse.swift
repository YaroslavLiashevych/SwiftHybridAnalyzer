//
//  AIReviewResponse.swift
//  Analyzer
//
//  Created by Yaroslav Liashevych on 10.05.2026.
//

import Foundation

struct AIReviewResponse: Codable {
    let summary: String
    let suggestions: [AISuggestion]
}
