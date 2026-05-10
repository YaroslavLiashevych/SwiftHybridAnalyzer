//
//  HybridDispatcher.swift
//  Analyzer
//
//  Created by Yaroslav Liashevych on 10.05.2026.
//

import Foundation
import SwiftSyntax
import SwiftParser

// Додай ці структури в MasterProject
struct AISuggestion: Codable {
    let line: Int
    let issue_type: String
    let explanation: String
    let original_code: String
    let fixed_code: String
}

struct AIReviewResponse: Codable {
    let summary: String
    let suggestions: [AISuggestion]
}

// Фінальна модель для відправки до ШІ
struct AIPayload: Codable {
    let analyzedFile: String
    let contexts: [EnhancedCodeContext]
    let totalIssuesFound: Int
    let issues: [CodeIssue]
    var aiReview: AIReviewResponse? // Нове поле для вердикту ШІ
}

class HybridDispatcher {
    let fileURL: URL
    let sourceFile: SourceFileSyntax
    let converter: SourceLocationConverter

    init(filePath: String) throws {
        self.fileURL = URL(fileURLWithPath: filePath)
        let content = try String(contentsOf: self.fileURL)
        self.sourceFile = Parser.parse(source: content)
        self.converter = SourceLocationConverter(fileName: self.fileURL.lastPathComponent, tree: self.sourceFile)
    }

    func analyzeAndPreparePayload() -> AIPayload {
        // 1. Збір семантичного контексту
        let contextVisitor = BaseASTVisitor(fileName: fileURL.lastPathComponent, converter: converter)
        contextVisitor.walk(sourceFile)

        // 2. Ініціалізація всіх правил (Rules)
        let memoryVisitor = MemorySafetyVisitor(converter: converter)
        let swiftUIVisitor = SwiftUIVisitor(converter: converter)
        let forceUnwrapVisitor = ForceUnwrapVisitor(converter: converter)
        let emptyCatchVisitor = EmptyCatchVisitor(converter: converter)
        let magicNumberVisitor = MagicNumberVisitor(converter: converter)
        let printVisitor = PrintVisitor(converter: converter)
        let massiveClassVisitor = MassiveClassVisitor(converter: converter)
        let localizationVisitor = LocalizationVisitor(converter: converter)
        let delegateVisitor = DelegateVisitor(converter: converter)
        let secretVisitor = SecretVisitor(converter: converter)

        // 3. Запуск аналізу
        let visitors: [SyntaxVisitor] = [
            memoryVisitor, swiftUIVisitor, forceUnwrapVisitor, emptyCatchVisitor,
            magicNumberVisitor, printVisitor, massiveClassVisitor, localizationVisitor,
            delegateVisitor, secretVisitor
        ]

        for visitor in visitors {
            visitor.walk(sourceFile)
        }

        // 4. Агрегація результатів
        var allIssues: [CodeIssue] = []
        allIssues.append(contentsOf: memoryVisitor.detectedIssues)
        allIssues.append(contentsOf: swiftUIVisitor.detectedIssues)
        allIssues.append(contentsOf: forceUnwrapVisitor.detectedIssues)
        allIssues.append(contentsOf: emptyCatchVisitor.detectedIssues)
        allIssues.append(contentsOf: magicNumberVisitor.detectedIssues)
        allIssues.append(contentsOf: printVisitor.detectedIssues)
        allIssues.append(contentsOf: massiveClassVisitor.detectedIssues)
        allIssues.append(contentsOf: localizationVisitor.detectedIssues)
        allIssues.append(contentsOf: delegateVisitor.detectedIssues)
        allIssues.append(contentsOf: secretVisitor.detectedIssues)

        // 5. Формування фінального пакету для LLM
        return AIPayload(
            analyzedFile: fileURL.lastPathComponent,
            contexts: contextVisitor.detectedContexts,
            totalIssuesFound: allIssues.count,
            issues: allIssues
        )
    }
}

