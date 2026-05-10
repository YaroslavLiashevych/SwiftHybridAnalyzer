//
//  AIPayload.swift
//  Analyzer
//
//  Created by Yaroslav Liashevych on 10.05.2026.
//

import Foundation

// Фінальна модель для відправки до ШІ
struct AIPayload: Codable {
    let analyzedFile: String
    let contexts: [EnhancedCodeContext]
    let totalIssuesFound: Int
    let issues: [CodeIssue]
    var aiReview: AIReviewResponse? 
}

