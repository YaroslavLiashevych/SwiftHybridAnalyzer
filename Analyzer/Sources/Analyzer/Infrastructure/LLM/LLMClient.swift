//
//  LLMClient.swift
//  Analyzer
//
//  Created by Yaroslav Liashevych on 10.05.2026.
//

import Foundation

// MARK: - Client Implementation
class LLMClient {
    private let apiKey: String
        private let endpoint = "https://api.groq.com/openai/v1/chat/completions"

        // "llama-3.1-8b-instant" — це сучасна швидка модель для розробки
        // "llama-3.3-70b-versatile" — потужна модель, можна переключатися мануально, якщо є на то потреба
        private let modelName = "llama-3.1-8b-instant"

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func sendReviewRequest(prompt: String) async throws -> String {
        // 1. Перевірка на mock
        if apiKey.lowercased() == "mock" {
            return generateMockResponse()
        }

        // 2. Валідація коду
        guard !prompt.isEmpty else {
            throw NSError(domain: "LLMClient", code: -3, userInfo: [NSLocalizedDescriptionKey: "Промпт порожній"])
        }

        guard let url = URL(string: endpoint) else { throw URLError(.badURL) }

        // 3. Формування запиту
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let groqReq = GroqRequest(
            model: modelName,
            messages: [
                GroqMessage(role: "system", content: "Ти — Senior iOS Developer. Пиши виключно українською."),
                GroqMessage(role: "user", content: prompt)
            ],
            temperature: 0.2,
            maxTokens: 2048
        )

        request.httpBody = try JSONEncoder().encode(groqReq)

        // 4. Виконання та діагностика
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.unknown)
        }

        if httpResponse.statusCode != 200 {
            // Якщо помилка 400+, виводимо текст помилки від сервера в консоль
            let serverError = String(data: data, encoding: .utf8) ?? "Невідома помилка"
            print("❌ Деталі помилки від Groq: \(serverError)")
            throw NSError(domain: "LLMClient", code: httpResponse.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: "Сервер повернув код \(httpResponse.statusCode). Дивіться лог вище."])
        }

        // 5. Декодування відповіді
        let decodedResponse = try JSONDecoder().decode(GroqResponse.self, from: data)
        return decodedResponse.choices.first?.message.content ?? "Помилка: Відповідь порожня"
    }

    private func generateMockResponse() -> String {
        return "🤖 [MOCK]: Система готова. Для реального аналізу вкажіть дійсний gsk-ключ."
    }
}
