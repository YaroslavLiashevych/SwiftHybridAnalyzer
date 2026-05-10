//
//  MemorySafetyRule.swift
//  Analyzer
//
//  Created by Yaroslav Liashevych on 10.05.2026.
//

import SwiftSyntax

import SwiftSyntax

class MemorySafetyVisitor: SyntaxVisitor {
    var detectedIssues: [CodeIssue] = []
    let converter: SourceLocationConverter

    init(converter: SourceLocationConverter) {
        self.converter = converter
        super.init(viewMode: .all)
    }

    // Шукаємо всі замикання (Closures) у коді
    override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
        let closureText = node.description

        // Перевіряємо, чи використовується 'self' всередині замикання
        let usesSelf = closureText.contains("self.")

        // Шукаємо список захоплення, наприклад: [weak self] або [unowned self]
        let captureList = node.signature?.capture
        let captureText = captureList?.description ?? ""

        let hasWeakOrUnowned = captureText.contains("weak") || captureText.contains("unowned")

        // ЯКЩО 'self' використовується, АЛЕ немає 'weak' чи 'unowned' -> Це потенційний витік пам'яті!
        if usesSelf && !hasWeakOrUnowned {
            let startLoc = node.startLocation(converter: converter)

            let issue = CodeIssue(
                issueType: "Memory Leak (ARC)",
                description: "Потенційний сильний цикл (Retain Cycle). Замикання захоплює 'self' без використання [weak self] або [unowned self].",
                line: startLoc.line
            )
            detectedIssues.append(issue)
        }

        // ВИПРАВЛЕНО ТУТ:
        return .visitChildren
    }
}

