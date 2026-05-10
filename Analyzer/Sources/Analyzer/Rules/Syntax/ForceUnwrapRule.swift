//
//  ForceUnwrapRule.swift
//  Analyzer
//
//  Created by Yaroslav Liashevych on 10.05.2026.
//

import SwiftSyntax

class ForceUnwrapVisitor: SyntaxVisitor {
    var detectedIssues: [CodeIssue] = []
    let converter: SourceLocationConverter

    init(converter: SourceLocationConverter) {
        self.converter = converter
        super.init(viewMode: .all)
    }

    // 1. Шукаємо примусове розгортання (наприклад: user!)
    override func visit(_ node: ForceUnwrapExprSyntax) -> SyntaxVisitorContinueKind {
        let startLoc = node.startLocation(converter: converter)
        // Витягуємо назву змінної, до якої застосовано '!'
        let expression = node.expression.description.trimmingCharacters(in: .whitespacesAndNewlines)

        let issue = CodeIssue(
            issueType: "Runtime Safety",
            description: "Критично: Знайдено Force Unwrapping ('\(expression)!'). Це може призвести до Fatal Error, якщо значення дорівнює nil. Використовуйте безпечне розгортання ('if let' або 'guard let').",
            line: startLoc.line
        )
        detectedIssues.append(issue)

        return .visitChildren
    }

    // 2. Шукаємо примусове приведення типів (наприклад: as! String)
    override func visit(_ node: AsExprSyntax) -> SyntaxVisitorContinueKind {
        // Перевіряємо, чи є знак оклику (бо може бути безпечний as?)
        if node.questionOrExclamationMark?.tokenKind == .exclamationMark {
            let startLoc = node.startLocation(converter: converter)
            let typeText = node.type.description.trimmingCharacters(in: .whitespacesAndNewlines)

            let issue = CodeIssue(
                issueType: "Runtime Safety",
                description: "Критично: Знайдено примусове приведення типів ('as! \(typeText)'). Це викличе краш під час виконання, якщо тип не збігається. Використовуйте 'as?'.",
                line: startLoc.line
            )
            detectedIssues.append(issue)
        }
        return .visitChildren
    }
}

