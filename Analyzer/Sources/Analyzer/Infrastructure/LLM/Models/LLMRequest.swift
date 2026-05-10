//
//  LLMRequest.swift
//  Analyzer
//
//  Created by Yaroslav Liashevych on 10.05.2026.
//

import Foundation

struct LLMRequest: Codable {
    let model: String
    let messages: [LLMMessage]
}
