//
//  ASTVisitor.swift
//  Analyzer
//
//  Created by Yaroslav Liashevych on 10.05.2026.
//

import SwiftSyntax

class BaseASTVisitor: SyntaxVisitor {
    var detectedContexts: [EnhancedCodeContext] = []
    let converter: SourceLocationConverter
    let fileName: String

    init(fileName: String, converter: SourceLocationConverter) {
        self.fileName = fileName
        self.converter = converter
        super.init(viewMode: .all)
    }

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        let name = node.name.text
        let startLoc = node.startLocation(converter: converter)

        let accessLevel = node.modifiers.first { modifier in
            ["public", "private", "fileprivate", "open", "internal"].contains(modifier.name.text)
        }?.name.text ?? "internal"

        var parentName: String? = nil
        var current: Syntax? = node.parent
        while current != nil {
            if let classDecl = current?.as(ClassDeclSyntax.self) {
                parentName = classDecl.name.text
                break
            } else if let structDecl = current?.as(StructDeclSyntax.self) {
                parentName = structDecl.name.text
                break
            }
            current = current?.parent
        }

        let attributes = node.attributes.map {
            $0.description.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Виклик сервісу метрик
        let complexity = ComplexityCalculator.calculate(for: node.body)

        let context = EnhancedCodeContext(
            fileName: self.fileName,
            entityName: name,
            entityType: "Function",
            sourceCode: node.description.trimmingCharacters(in: .whitespacesAndNewlines),
            startLine: startLoc.line,
            complexityScore: complexity, 
            attributes: attributes,
            accessLevel: accessLevel,
            parentEntity: parentName
        )

        detectedContexts.append(context)
        return .skipChildren
    }
}
