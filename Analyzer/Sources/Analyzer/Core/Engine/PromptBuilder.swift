//
//  PromptBuilder.swift
//  Analyzer
//
//  Created by Yaroslav Liashevych on 10.05.2026.
//

import Foundation

/// Сервіс для генерації prompts до LLM з посиленим контролем JSON.
struct PromptBuilder {

    private static var personaInstructions: String {
        return """
        ТВОЯ РОЛЬ:
        Ти — Senior iOS Developer та системний архітектор з глибоким знанням Swift 6 та SwiftUI.
        
        ПРАВИЛА ТА ОБМЕЖЕННЯ:
        1. Пріоритет аналізу: Безпека пам'яті (ARC), багатопотоковість (Concurrency) та архітектурна цілісність (SOLID).
        2. Формат відповіді: Будь критичним, але конструктивним. Надавай розгорнуті пояснення причин помилок.
        3. Технологічний стек: Використовуй лише актуальні API (Swift 6, SwiftUI, Combine).
        4. Мова: Відповідь має бути виключно УКРАЇНСЬКОЮ мовою у професійному технічному стилі.
        """
    }

    static func build(from payload: AIPayload) -> String {

        let issuesList = payload.issues.isEmpty
            ? "Критичних синтаксичних та структурних порушень не виявлено."
            : payload.issues.map { issue in
                "- [Рядок \(issue.line)] [\(issue.issueType)]: \(issue.description)"
            }.joined(separator: "\n")

        let codeContexts = payload.contexts.map { context in
            """
            ---
            ОБ'ЄКТ: \(context.entityName) (\(context.entityType))
            ДОСТУП: \(context.accessLevel)
            МЕТРИКА СКЛАДНОСТІ: \(context.complexityScore)
            ВИХІДНИЙ КОД:
            \(context.sourceCode)
            """
        }.joined(separator: "\n")

        return """
            \(personaInstructions)

            ІНФОРМАЦІЯ ПРО ПРОЄКТ:
            - Файл: \(payload.analyzedFile)
            - Загальна кількість технічних зауважень: \(payload.totalIssuesFound)

            РЕЗУЛЬТАТИ СТАТИЧНОГО АНАЛІЗУ (AST LEVEL):
            \(issuesList)

            СЕМАНТИЧНИЙ КОНТЕКСТ ФАЙЛУ:
            \(codeContexts)

            🚨 ВАЖЛИВА ІНСТРУКЦІЯ ЩОДО JSON ФОРМАТУ: 🚨
            Поверни відповідь ВИКЛЮЧНО у валідному форматі JSON. 
            НЕ додавай жодних пояснень ДО або ПІСЛЯ об'єкта JSON.

            ПРАВИЛА ДЛЯ `original_code` ТА `fixed_code`:
            Ти повинен суворо дотримуватися правил екранування JSON для Swift-коду.
            
            ПРИКЛАДИ ЕКРАНУВАННЯ:
            - Код: print("Hello") -> JSON: "print(\\"Hello\\")"
            - Код: \\(name) -> JSON: "\\\\(name)" (два бекслеші)
            - Код: let url = URL(string: "url")! -> JSON: "let url = URL(string: \\"url\\")!"
            
            ДОДАТКОВІ ПРАВИЛА:
            1. Весь код у полі `fixed_code` має бути в один рядок (використовуй \\n для нових рядків).
            2. Не використовуй конкатенацію рядків (+) у виправленому коді, пиши цілісний фрагмент.

            СТРУКТУРА JSON:
            {
              "summary": "Загальний висновок про стан коду (укр. мовою)",
              "suggestions": [
                {
                  "line": 15,
                  "issue_type": "Тип помилки (Memory, Security, Architecture)",
                  "explanation": "Детальне пояснення проблеми українською",
                  "original_code": "фрагмент коду з помилкою",
                  "fixed_code": "повністю виправлений фрагмент коду"
                }
              ]
            }
            """
    }
}
