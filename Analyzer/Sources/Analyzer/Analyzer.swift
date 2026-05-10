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
                let review = try await llmClient.sendReviewRequest(prompt: PromptBuilder.build(from: payload))
                payload.aiReview = review
                print("✅ AI Review отримано.")
            }

            // Формуємо JSON
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
            let jsonData = try encoder.encode(payload)

            // ЛОГІКА ЗБЕРЕЖЕННЯ
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
