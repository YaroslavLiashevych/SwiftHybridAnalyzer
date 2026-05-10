// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import ArgumentParser

@main
struct AnalyzerCommand: AsyncParsableCommand {
    @Argument(help: "Шлях до файлу Swift")
    var filePath: String

    @Option(name: .shortAndLong, help: "API ключ для LLM (або 'mock')")
    var apiKey: String?

    @Option(name: .shortAndLong, help: "Шлях для збереження фінального JSON-звіту")
    var output: String?

    func run() async throws {
        print("🔍 Аналіз: \(filePath)...")

        do {
            let dispatcher = try HybridDispatcher(filePath: filePath)
            var payload = dispatcher.analyzeAndPreparePayload()

            // Якщо є ключ, отримуємо AI Review
            if let key = apiKey {
                print("🚀 Запит до LLM (Level 2)...")
                let llmClient = LLMClient(apiKey: key)

                // 1. Отримуємо відповідь як рядок
                let rawReviewString = try await llmClient.sendReviewRequest(prompt: PromptBuilder.build(from: payload))

                // 2. Очищення відповіді (Витягуємо лише JSON від { до })
                // Це рятує парсер, якщо ШІ додав Markdown (```json) або зайвий текст
                var cleanedString = rawReviewString
                if let startIndex = cleanedString.firstIndex(of: "{"),
                   let endIndex = cleanedString.lastIndex(of: "}") {
                    cleanedString = String(cleanedString[startIndex...endIndex])
                }

                // Виводимо в консоль для дебагу
                print("📦 Очищений JSON для парсингу: \n\(cleanedString)\n")

                // 3. Спробуємо перетворити очищений рядок (JSON) у наш об'єкт AIReviewResponse
                if let jsonData = cleanedString.data(using: .utf8) {
                    do {
                        let decodedReview = try JSONDecoder().decode(AIReviewResponse.self, from: jsonData)
                        payload.aiReview = decodedReview // Тепер це об'єкт, а не текст
                        print("✅ AI Review успішно деserialized.")
                    } catch {
                        print("⚠️ Помилка парсингу JSON від ШІ: \(error.localizedDescription)")
                    }
                }
            }

            // Формуємо фінальний JSON для Action
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
            let jsonData = try encoder.encode(payload)

            // Логіка збереження
            if let outputPath = output {
                let fileURL = URL(fileURLWithPath: outputPath)
                try jsonData.write(to: fileURL)
                print("💾 Звіт успішно збережено у: \(outputPath)")
            } else {
                // Якщо шлях не вказано, просто виводимо в консоль
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    print("\n--- ФІНАЛЬНИЙ ЗВІТ ---")
                    print(jsonString)
                }
            }

        } catch {
            print("❌ Помилка: \(error.localizedDescription)")
        }
    }
}
