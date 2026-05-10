//
//  AISuggestion.swift
//  Analyzer
//
//  Created by Yaroslav Liashevych on 10.05.2026.
//

import Foundation

struct AISuggestion: Codable {
    let line: Int
    let issue_type: String
    let explanation: String
    let original_code: String
    let fixed_code: String
}
