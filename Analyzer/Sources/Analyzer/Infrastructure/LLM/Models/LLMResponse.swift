//
//  LLMResponse.swift
//  Analyzer
//
//  Created by Yaroslav Liashevych on 10.05.2026.
//

import Foundation

struct LLMResponse: Codable {
    struct Choice: Codable {
        let message: LLMMessage
    }
    let choices: [Choice]
}

