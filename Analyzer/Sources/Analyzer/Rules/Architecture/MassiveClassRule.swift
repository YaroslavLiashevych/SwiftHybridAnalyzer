//
//  MassiveClassRule.swift
//  Analyzer
//
//  Created by Yaroslav Liashevych on 10.05.2026.
//

import SwiftSyntax

class MassiveClassVisitor: SyntaxVisitor {
    var detectedIssues: [CodeIssue] = []
    let converter: SourceLocationConverter

    // Встановлюємо ліміт: 10 методів на один клас
    let methodLimit = 10

    init(converter: SourceLocationConverter) {
        self.converter = converter
        super.init(viewMode: .all)
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        let className = node.name.text

        // Збираємо всі методи класу
        let methods = node.memberBlock.members.compactMap { member in
            member.decl.as(FunctionDeclSyntax.self)
        }

        // Якщо кількість методів перевищує ліміт — це God Object
        if methods.count >= methodLimit {
            let startLoc = node.startLocation(converter: converter)

            let issue = CodeIssue(
                issueType: "Architecture (SRP Violation)",
                description: "Знайдено 'God Object'. Клас '\(className)' має забагато методів (\(methods.count)). Це порушує принцип Single Responsibility. Рекомендується розділити логіку на менші, спеціалізовані компоненти (наприклад, винести мережу чи форматування).",
                line: startLoc.line
            )
            detectedIssues.append(issue)
        }

        return .visitChildren
    }
}

