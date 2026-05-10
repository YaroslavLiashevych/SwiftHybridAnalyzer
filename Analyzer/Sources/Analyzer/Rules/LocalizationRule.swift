//
//  LocalizationRule.swift
//  Analyzer
//
//  Created by Yaroslav Liashevych on 10.05.2026.
//

import SwiftSyntax

class LocalizationVisitor: SyntaxVisitor {
    var detectedIssues: [CodeIssue] = []
    let converter: SourceLocationConverter

    init(converter: SourceLocationConverter) {
        self.converter = converter
        super.init(viewMode: .all)
    }

    override func visit(_ node: StringLiteralExprSyntax) -> SyntaxVisitorContinueKind {
        // Витягуємо текст, який знаходиться всередині лапок
        let textValue = node.segments.description

        // Евристика: якщо рядок не порожній і містить пробіл — це, швидше за все, фраза для UI
        if textValue.contains(" ") && textValue.count > 3 {
            let startLoc = node.startLocation(converter: converter)

            let issue = CodeIssue(
                issueType: "Localization (i18n)",
                description: "Знайдено захардкоджений рядок (\"\(textValue)\"). Уникайте використання 'сирих' рядків для інтерфейсу користувача. Використовуйте 'String(localized:)' або механізми локалізації вашого фреймворку.",
                line: startLoc.line
            )
            detectedIssues.append(issue)
        }

        return .visitChildren
    }
}

