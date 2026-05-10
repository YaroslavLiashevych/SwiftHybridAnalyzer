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

            if let key = apiKey {
                print("🚀 Запит до LLM (Level 2)...")
                let llmClient = LLMClient(apiKey: key)

                // 1. Отримуємо сиру відповідь від ШІ
                let rawReviewString = try await llmClient.sendReviewRequest(prompt: PromptBuilder.build(from: payload))

                // 2. ВИКОРИСТОВУЄМО ОНОВЛЕНЕ ОЧИЩЕННЯ
                // Тепер тут працює Regex, який фіксить екранування інтерполяції
                let cleanedString = HybridDispatcher.cleanJSONResponse(rawReviewString)

                // Виводимо в консоль для дебагу
                print("📦 Очищений JSON для парсингу: \n\(cleanedString)\n")

                // 3. Десеріалізація
                if let jsonData = cleanedString.data(using: .utf8) {
                    do {
                        let decodedReview = try JSONDecoder().decode(AIReviewResponse.self, from: jsonData)
                        payload.aiReview = decodedReview
                        print("✅ AI Review успішно деserialized.")
                    } catch {
                        print("⚠️ Помилка парсингу JSON від ШІ: \(error.localizedDescription)")
                        // Додатковий лог для розробника, щоб бачити де саме зламався JSON
                        print("Порада: Перевірте екранування лапок та зворотних слешів у відповіді.")
                    }
                }
            }

            // Формуємо фінальний JSON
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
            let jsonData = try encoder.encode(payload)

            if let outputPath = output {
                let fileURL = URL(fileURLWithPath: outputPath)
                try jsonData.write(to: fileURL)
                print("💾 Звіт успішно збережено у: \(outputPath)")
            } else {
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
