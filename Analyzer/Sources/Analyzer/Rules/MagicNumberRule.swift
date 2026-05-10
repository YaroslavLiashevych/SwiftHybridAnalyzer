//
//  MagicNumberRule.swift
//  Analyzer
//
//  Created by Yaroslav Liashevych on 10.05.2026.
//

import SwiftSyntax

class MagicNumberVisitor: SyntaxVisitor {
    var detectedIssues: [CodeIssue] = []
    let converter: SourceLocationConverter

    init(converter: SourceLocationConverter) {
        self.converter = converter
        super.init(viewMode: .all)
    }

    override func visit(_ node: IntegerLiteralExprSyntax) -> SyntaxVisitorContinueKind {
        // Намагаємося перетворити текст вузла на число
        let textValue = node.literal.text
        if let value = Int(textValue) {
            // Ігноруємо 0 та 1, оскільки вони часто використовуються для ініціалізації чи індексів
            if value > 1 || value < -1 {
                let startLoc = node.startLocation(converter: converter)

                let issue = CodeIssue(
                    issueType: "Code Maintainability (Magic Number)",
                    description: "Знайдено 'магічне число' (\(value)). Жорстко закодовані числа погіршують читабельність та підтримку коду. Рекомендується винести це значення в іменовану константу.",
                    line: startLoc.line
                )
                detectedIssues.append(issue)
            }
        }
        return .visitChildren
    }
}

