//
//  LLMModels.swift
//  Analyzer
//
//  Created by Yaroslav Liashevych on 10.05.2026.
//

import Foundation

struct LLMRequest: Codable {
    let model: String
    let messages: [LLMMessage]
}

struct LLMMessage: Codable {
    let role: String
    let content: String
}

struct LLMResponse: Codable {
    struct Choice: Codable {
        let message: LLMMessage
    }
    let choices: [Choice]
}

