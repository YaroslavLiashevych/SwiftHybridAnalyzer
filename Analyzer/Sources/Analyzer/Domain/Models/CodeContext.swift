//
//  CodeContext.swift
//  Analyzer
//
//  Created by Yaroslav Liashevych on 10.05.2026.
//

import Foundation

struct EnhancedCodeContext: Codable {
    let fileName: String
    let entityName: String
    let entityType: String
    let sourceCode: String
    let startLine: Int
    let complexityScore: Int
    let attributes: [String]
    let accessLevel: String
    let parentEntity: String? 
}
