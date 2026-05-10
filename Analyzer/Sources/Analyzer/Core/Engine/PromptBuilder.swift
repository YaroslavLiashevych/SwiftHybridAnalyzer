//
//  PromptBuilder.swift
//  Analyzer
//
//  Created by Yaroslav Liashevych on 10.05.2026.
//

import Foundation

/// Сервіс для генерації prompts до LLM.
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
            
            ПРАВИЛА ДЛЯ ПОЛІВ `original_code` ТА `fixed_code`:
            1. АБСОЛЮТНО ЗАБОРОНЕНО використовувати конкатенацію (знаки +) між рядками. Весь код має бути одним суцільним рядком.
            2. ОБОВ'ЯЗКОВО екрануй подвійні лапки всередині коду за допомогою бекслеша: `\\"`
            3. ОБОВ'ЯЗКОВО екрануй символи нового рядка як `\\n`.
            4. ОБОВ'ЯЗКОВО екрануй слеші для Swift-інтерполяції рядків (пиши `\\\\(variable)` замість `\\(variable)`).
            
            СТРУКТУРА JSON:
            {
              "summary": "Загальний висновок про стан коду",
              "suggestions": [
                {
                  "line": 15,
                  "issue_type": "Retain Cycle",
                  "explanation": "Пояснення проблеми",
                  "original_code": "код який треба замінити",
                  "fixed_code": "повністю виправлений фрагмент коду"
                }
              ]
            }
            """
    }
}
