//
//  EmptyCatchRule.swift
//  Analyzer
//
//  Created by Yaroslav Liashevych on 10.05.2026.
//

import SwiftSyntax

class EmptyCatchVisitor: SyntaxVisitor {
    var detectedIssues: [CodeIssue] = []
    let converter: SourceLocationConverter

    init(converter: SourceLocationConverter) {
        self.converter = converter
        super.init(viewMode: .all)
    }

    override func visit(_ node: CatchClauseSyntax) -> SyntaxVisitorContinueKind {
        // Перевіряємо, чи є хоч якийсь код всередині тіла catch { ... }
        if node.body.statements.isEmpty {
            let startLoc = node.startLocation(converter: converter)

            let issue = CodeIssue(
                issueType: "Error Handling (Anti-pattern)",
                description: "Знайдено порожній блок 'catch'. Помилка 'проковтується' без жодної обробки чи логування. Це критично ускладнює відлагодження програми.",
                line: startLoc.line
            )
            detectedIssues.append(issue)
        }

        return .visitChildren
    }
}

