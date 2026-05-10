//
//  HybridDispatcher.swift
//  Analyzer
//
//  Created by Yaroslav Liashevych on 10.05.2026.
//

import Foundation
import SwiftSyntax
import SwiftParser

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

    /// Крок 1: Збір даних за допомогою статичного аналізу (AST)
    func analyzeAndPreparePayload() -> AIPayload {
        // 1. Збір семантичного контексту
        let contextVisitor = BaseASTVisitor(fileName: fileURL.lastPathComponent, converter: converter)
        contextVisitor.walk(sourceFile)

        // 2. Ініціалізація правил
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

        let visitors: [SyntaxVisitor] = [
            memoryVisitor, swiftUIVisitor, forceUnwrapVisitor, emptyCatchVisitor,
            magicNumberVisitor, printVisitor, massiveClassVisitor, localizationVisitor,
            delegateVisitor, secretVisitor
        ]

        for visitor in visitors {
            visitor.walk(sourceFile)
        }

        // 3. Агрегація знайдених зауважень
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

        return AIPayload(
            analyzedFile: fileURL.lastPathComponent,
            contexts: contextVisitor.detectedContexts,
            totalIssuesFound: allIssues.count,
            issues: allIssues
        )
    }

    /// Крок 2: Очищення відповіді від ШІ (використовуй цей метод перед JSONDecoder)
    static func cleanJSONResponse(_ rawResponse: String) -> String {
        var cleaned = rawResponse

        // 1. Видаляємо Markdown-обгортки ```json ... ```
        if cleaned.contains("```") {
            let components = cleaned.components(separatedBy: "```")
            for component in components {
                if component.contains("{") && component.contains("}") {
                    cleaned = component.replacingOccurrences(of: "json", with: "")
                    break
                }
            }
        }

        // 2. Знаходимо межі JSON (від першої { до останньої })
        if let firstBrace = cleaned.firstIndex(of: "{"),
           let lastBrace = cleaned.lastIndex(of: "}") {
            cleaned = String(cleaned[firstBrace...lastBrace])
        }

        // 3. ВИПРАВЛЕННЯ ЕКРАНУВАННЯ (Regex):
        // Замінюємо поодинокі бекслеші перед дужкою \( на подвійні \\(
        // Це критично для валідності JSON при передачі Swift-інтерполяції.
        let pattern = #"(?<!\\)\\\("#
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let range = NSRange(cleaned.startIndex..., in: cleaned)
            cleaned = regex.stringByReplacingMatches(in: cleaned, options: [], range: range, withTemplate: #"\\\\("#)
        }

        // Видаляємо можливі невалідні переноси рядків всередині значень (якщо вони не екрановані)
        // Примітка: Ми не видаляємо всі \n, а лише ті, що можуть зламати структуру.
        // Але оскільки ми просимо ШІ використовувати \n, тут краще просто обрізати зайве по краях.

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
