//
//  SecretRule.swift
//  Analyzer
//
//  Created by Yaroslav Liashevych on 10.05.2026.
//

import SwiftSyntax

class SecretVisitor: SyntaxVisitor {
    var detectedIssues: [CodeIssue] = []
    let converter: SourceLocationConverter

    init(converter: SourceLocationConverter) {
        self.converter = converter
        super.init(viewMode: .all)
    }

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        let secretKeywords = ["apikey", "token", "password", "secret"]

        for binding in node.bindings {
            if let identifier = binding.pattern.as(IdentifierPatternSyntax.self) {
                let varName = identifier.identifier.text.lowercased()

                // Перевіряємо, чи натякає назва змінної на конфіденційні дані
                let isSecret = secretKeywords.contains { varName.contains($0) }

                if isSecret {
                    // Якщо це секрет і йому одразу присвоюється рядок (хардкод)
                    if let initializer = binding.initializer,
                       initializer.value.is(StringLiteralExprSyntax.self) {

                        let startLoc = node.startLocation(converter: converter)
                        let issue = CodeIssue(
                            issueType: "Security",
                            description: "Критично: Знайдено хардкод конфіденційних даних у змінній '\(identifier.identifier.text)'. Використовуйте Keychain або змінні середовища для зберігання секретів.",
                            line: startLoc.line
                        )
                        detectedIssues.append(issue)
                    }
                }
            }
        }
        return .visitChildren
    }
}

