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
        // 1. Збір семантичного контексту (структура класів, методів тощо)
        let contextVisitor = BaseASTVisitor(fileName: fileURL.lastPathComponent, converter: converter)
        contextVisitor.walk(sourceFile)

        // 2. Ініціалізація всіх правил аналізу
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

        // 3. Запуск обходу дерева коду
        let visitors: [SyntaxVisitor] = [
            memoryVisitor, swiftUIVisitor, forceUnwrapVisitor, emptyCatchVisitor,
            magicNumberVisitor, printVisitor, massiveClassVisitor, localizationVisitor,
            delegateVisitor, secretVisitor
        ]

        for visitor in visitors {
            visitor.walk(sourceFile)
        }

        // 4. Агрегація знайдених "зачіпок" для ШІ
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

        // 1. Видаляємо Markdown-обгортки ```json ... ``` якщо вони є
        if cleaned.contains("```json") {
            cleaned = cleaned.components(separatedBy: "```json").last ?? cleaned
            cleaned = cleaned.components(separatedBy: "```").first ?? cleaned
        }

        // 2. Знаходимо межі JSON (від першої { до останньої })
        // Це відсікає будь-який зайвий текст від ШІ на початку або в кінці
        if let firstBrace = cleaned.firstIndex(of: "{"),
           let lastBrace = cleaned.lastIndex(of: "}") {
            cleaned = String(cleaned[firstBrace...lastBrace])
        }

        // 3. ВИПРАВЛЕННЯ ЕКРАНУВАННЯ:
        // ШІ часто помиляється і пише \(variable) всередині JSON-рядка.
        // Це ламає парсер. Нам потрібно замінити \( на \\(
        // Але спочатку перевіряємо, чи воно вже не екрановане
        cleaned = cleaned.replacingOccurrences(of: "\\(", with: "\\\\(")

        // Видаляємо можливі дубльовані бекслеші, які могли виникнути при подвійному фіксі
        cleaned = cleaned.replacingOccurrences(of: "\\\\\\(", with: "\\\\(")

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
