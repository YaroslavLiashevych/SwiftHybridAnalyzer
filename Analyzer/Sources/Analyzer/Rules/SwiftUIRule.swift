//
//  SwiftUIRule.swift
//  Analyzer
//
//  Created by Yaroslav Liashevych on 10.05.2026.
//

import SwiftSyntax

class SwiftUIVisitor: SyntaxVisitor {
    var detectedIssues: [CodeIssue] = []
    let converter: SourceLocationConverter

    init(converter: SourceLocationConverter) {
        self.converter = converter
        super.init(viewMode: .all)
    }

    // Шукаємо декларації КЛАСІВ
    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        let className = node.name.text

        // Перевіряємо всі властивості (змінні) всередині класу
        for member in node.memberBlock.members {
            if let varDecl = member.decl.as(VariableDeclSyntax.self) {
                // Чи є у цієї змінної атрибут @State?
                let hasStateAttribute = varDecl.attributes.contains { attr in
                    attr.description.contains("@State")
                }

                if hasStateAttribute {
                    let startLoc = varDecl.startLocation(converter: converter)
                    let issue = CodeIssue(
                        issueType: "SwiftUI Architecture",
                        description: "Критична помилка: @State використовується всередині класу '\(className)'. Обгортка @State призначена лише для структур (View). Для класів використовуйте @Published.",
                        line: startLoc.line
                    )
                    detectedIssues.append(issue)
                }
            }
        }

        return .visitChildren
    }
}

