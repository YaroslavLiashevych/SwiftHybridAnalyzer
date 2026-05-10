//
//  PromptBuilder.swift
//  Analyzer
//
//  Created by Yaroslav Liashevych on 10.05.2026.
//

import Foundation

/// Сервіс для генерації контекстуальних запитів (prompts) до LLM.
/// Реалізує другий рівень гібридного аналізу коду[cite: 106].
struct PromptBuilder {

    // MARK: - Persona & Rules

    /// Набір інструкцій, що визначають поведінку ШІ як Senior iOS розробника[cite: 103].
    private static var personaInstructions: String {
        return """
        ТВОЯ РОЛЬ:
        Ти — Senior iOS Developer та системний архітектор з глибоким знанням Swift 6 та SwiftUI.
        
        ПРАВИЛА ТА ОБМЕЖЕННЯ:
        1. Пріоритет аналізу: Безпека пам'яті (ARC), багатопотоковість (Concurrency) та архітектурна цілісність (SOLID)[cite: 50, 115].
        2. Формат відповіді: Будь критичним, але конструктивним. Надавай розгорнуті пояснення причин помилок[cite: 103].
        3. Технологічний стек: Використовуй лише актуальні API (Swift 6, SwiftUI, Combine). Уникай застарілих практик[cite: 115, 117].
        4. Пояснення ARC: Якщо знайдено Retain Cycle, поясни механізм витоку (Strong vs Weak)[cite: 49, 50].
        5. Рефакторинг: Для методів з високою складністю (Complexity > 5) завжди пропонуй декомпозицію (Extract Method)[cite: 69].
        6. Мова: Відповідь має бути виключно УКРАЇНСЬКОЮ мовою у професійному технічному стилі.
        """
    }

    // MARK: - Builder Logic

    /// Генерує фінальний промпт на основі даних від детермінованого аналізатора[cite: 107].
    static func build(from payload: AIPayload) -> String {

        // Формуємо список помилок, знайдених на першому етапі (AST)
        let issuesList = payload.issues.isEmpty
            ? "Критичних синтаксичних та структурних порушень не виявлено."
            : payload.issues.map { issue in
                "- [Рядок \(issue.line)] [\(issue.issueType)]: \(issue.description)"
            }.joined(separator: "\n")

        // Формуємо семантичний контекст (код функцій/класів та їх метрики)
        let codeContexts = payload.contexts.map { context in
            """
            ---
            ОБ'ЄКТ: \(context.entityName) (\(context.entityType))
            ДОСТУП: \(context.accessLevel)
            КОНТЕКСТ (Parent): \(context.parentEntity ?? "Global")
            МЕТРИКА СКЛАДНОСТІ: \(context.complexityScore)
            ВИХІДНИЙ КОД:
            \(context.sourceCode)
            """
        }.joined(separator: "\n")

        // Збираємо фінальну структуру промпту
        return """
            \(personaInstructions)

            ІНФОРМАЦІЯ ПРО ПРОЄКТ:
            - Файл: \(payload.analyzedFile)
            - Загальна кількість технічних зауважень: \(payload.totalIssuesFound)

            РЕЗУЛЬТАТИ СТАТИЧНОГО АНАЛІЗУ (AST LEVEL):
            \(issuesList)

            СЕМАНТИЧНИЙ КОНТЕКСТ ФАЙЛУ:
            \(codeContexts)

            🚨 ВАЖЛИВА ІНСТРУКЦІЯ: 🚨
            Поверни відповідь ВИКЛЮЧНО у форматі JSON. Не пиши жодних вступних слів чи пояснень поза JSON.
            
            СТРУКТУРА JSON:
            {
              "summary": "Загальний висновок про стан коду",
              "suggestions": [
                {
                  "line": 15,
                  "issue_type": "Retain Cycle",
                  "explanation": "Пояснення людською мовою",
                  "original_code": "код який треба замінити",
                  "fixed_code": "повністю виправлений фрагмент коду"
                }
              ]
            }

            Якщо помилок не знайдено, поверни порожній список suggestions.
            """
    }
}
