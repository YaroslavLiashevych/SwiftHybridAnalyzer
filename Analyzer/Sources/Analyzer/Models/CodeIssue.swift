//
//  CodeIssue.swift
//  Analyzer
//
//  Created by Yaroslav Liashevych on 10.05.2026.
//

import Foundation

// Модель для зберігання знайдених вразливостей або помилок
struct CodeIssue: Codable {
    let issueType: String
    let description: String
    let line: Int
}

