//
//  DelegateRule.swift
//  Analyzer
//
//  Created by Yaroslav Liashevych on 10.05.2026.
//

import SwiftSyntax

class DelegateVisitor: SyntaxVisitor {
    var detectedIssues: [CodeIssue] = []
    let converter: SourceLocationConverter

    init(converter: SourceLocationConverter) {
        self.converter = converter
        super.init(viewMode: .all)
    }

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        // Перевіряємо кожну змінну у декларації
        for binding in node.bindings {
            if let identifier = binding.pattern.as(IdentifierPatternSyntax.self) {
                let varName = identifier.identifier.text.lowercased()

                // Якщо змінна має в назві слово "delegate"
                if varName.contains("delegate") {

                    // Перевіряємо, чи є серед модифікаторів слово "weak"
                    let hasWeak = node.modifiers.contains { modifier in
                        modifier.name.text == "weak"
                    }

                    if !hasWeak {
                        let startLoc = node.startLocation(converter: converter)
                        let issue = CodeIssue(
                            issueType: "Memory Leak (ARC)",
                            description: "Знайдено делегат ('\(identifier.identifier.text)') без ключового слова 'weak'. Це класична причина сильних циклічних посилань (Retain Cycle). Завжди оголошуйте делегати як 'weak var'.",
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

