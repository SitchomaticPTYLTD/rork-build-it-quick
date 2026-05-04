import Foundation

nonisolated final class AIModifierService: Sendable {
    private let keychain: AIKeychainStore
    private let session: URLSession

    init(
        keychain: AIKeychainStore = .shared,
        session: URLSession = .shared
    ) {
        self.keychain = keychain
        self.session = session
    }

    func process(text: String, mode: MorphMode) async throws -> String {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { throw AIModifierError.emptyInput }

        let groqKey = AIProvider.groq.resolvedKey(keychain: keychain)
        let geminiKey = AIProvider.gemini.resolvedKey(keychain: keychain)

        if !groqKey.isEmpty {
            do {
                let result = try await processWithGroq(text: trimmedText, mode: mode, apiKey: groqKey)
                if !result.isEmpty { return result }
            } catch is CancellationError {
                throw AIModifierError.cancelled
            } catch {
                // Silent primary-to-fallback behavior: user only sees an error if all configured providers fail.
            }
        }

        if !geminiKey.isEmpty {
            let result = try await processWithGemini(text: trimmedText, mode: mode, apiKey: geminiKey)
            guard !result.isEmpty else { throw AIModifierError.emptyResponse }
            return result
        }

        throw AIModifierError.missingAPIKeys
    }

    private func processWithGroq(text: String, mode: MorphMode, apiKey: String) async throws -> String {
        var request = URLRequest(url: AIProvider.groq.url)
        request.httpMethod = "POST"
        request.timeoutInterval = 45
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let payload = GroqChatRequest(
            model: AIProvider.groq.model,
            messages: [
                GroqMessage(role: "system", content: "You are a precision text modification engine. Follow the requested transformation exactly. Return only the transformed text with no commentary."),
                GroqMessage(role: "user", content: "\(mode.prompt)\n\nTEXT:\n\(text)")
            ],
            temperature: 0.25
        )
        request.httpBody = try JSONEncoder().encode(payload)

        let data = try await validatedData(for: request)
        let response = try JSONDecoder().decode(GroqChatResponse.self, from: data)
        let output = response.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !output.isEmpty else { throw AIModifierError.emptyResponse }
        return output
    }

    private func processWithGemini(text: String, mode: MorphMode, apiKey: String) async throws -> String {
        var components = URLComponents(url: AIProvider.gemini.url, resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "key", value: apiKey)]
        guard let url = components?.url else { throw AIModifierError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 45
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let payload = GeminiGenerateRequest(
            contents: [
                GeminiContent(parts: [
                    GeminiPart(text: "\(mode.prompt)\n\nTEXT:\n\(text)")
                ])
            ]
        )
        request.httpBody = try JSONEncoder().encode(payload)

        let data = try await validatedData(for: request)
        let response = try JSONDecoder().decode(GeminiGenerateResponse.self, from: data)
        let output = response.candidates.first?.content.parts.first?.text.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !output.isEmpty else { throw AIModifierError.emptyResponse }
        return output
    }

    private func validatedData(for request: URLRequest) async throws -> Data {
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIModifierError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw AIModifierError.httpStatus(httpResponse.statusCode)
        }
        return data
    }
}
