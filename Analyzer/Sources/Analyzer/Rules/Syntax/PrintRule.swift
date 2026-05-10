//
//  PrintRule.swift
//  Analyzer
//
//  Created by Yaroslav Liashevych on 10.05.2026.
//

import SwiftSyntax

class PrintVisitor: SyntaxVisitor {
    var detectedIssues: [CodeIssue] = []
    let converter: SourceLocationConverter

    init(converter: SourceLocationConverter) {
        self.converter = converter
        super.init(viewMode: .all)
    }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        // Перевіряємо, чи є вираз, який викликається, посиланням на декларацію (ім'ям функції)
        if let declRef = node.calledExpression.as(DeclReferenceExprSyntax.self) {
            // Якщо ім'я функції - "print"
            if declRef.baseName.text == "print" {
                let startLoc = node.startLocation(converter: converter)

                let issue = CodeIssue(
                    issueType: "Security & Performance",
                    description: "Попередження: Знайдено використання 'print()'. Залишати print у продакшен-коді небезпечно, оскільки це може призвести до витоку конфіденційних даних (PII) у системні логи, а також знижує продуктивність. Використовуйте 'OSLog' або 'Logger'.",
                    line: startLoc.line 
                )
                detectedIssues.append(issue)
            }
        }
        return .visitChildren
    }
}

