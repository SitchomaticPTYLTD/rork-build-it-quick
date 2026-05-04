import Foundation

nonisolated final class PatternLearningService: Sendable {
    private let keychain: AIKeychainStore
    private let session: URLSession

    init(
        keychain: AIKeychainStore = .shared,
        session: URLSession = .shared
    ) {
        self.keychain = keychain
        self.session = session
    }

    // MARK: - Public API

    func analyze(examples: [ExamplePair], refinement: String) async throws -> LearnedPattern {
        let usable = examples.filter { $0.isUsable }
        guard !usable.isEmpty else { throw AIModifierError.emptyInput }

        let prompt = Self.analysisPrompt(examples: usable, refinement: refinement)
        let raw = try await callAI(systemPrompt: Self.analysisSystem, userPrompt: prompt, temperature: 0.1)
        return Self.parseLearnedPattern(from: raw)
    }

    func apply(
        rule: String,
        refinement: String,
        examples: [ExamplePair],
        chunk: String
    ) async throws -> String {
        let trimmedChunk = chunk.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedChunk.isEmpty else { return "" }
        let prompt = Self.applyPrompt(rule: rule, refinement: refinement, examples: examples, chunk: chunk)
        return try await callAI(systemPrompt: Self.applySystem, userPrompt: prompt, temperature: 0.0)
    }

    // MARK: - Provider calls (Groq → Gemini failover)

    private func callAI(systemPrompt: String, userPrompt: String, temperature: Double) async throws -> String {
        let groqKey = AIProvider.groq.resolvedKey(keychain: keychain)
        let geminiKey = AIProvider.gemini.resolvedKey(keychain: keychain)

        if !groqKey.isEmpty {
            do {
                let result = try await callGroq(
                    systemPrompt: systemPrompt,
                    userPrompt: userPrompt,
                    temperature: temperature,
                    apiKey: groqKey
                )
                if !result.isEmpty { return result }
            } catch is CancellationError {
                throw AIModifierError.cancelled
            } catch {
                // silent failover
            }
        }

        if !geminiKey.isEmpty {
            let result = try await callGemini(
                systemPrompt: systemPrompt,
                userPrompt: userPrompt,
                apiKey: geminiKey
            )
            guard !result.isEmpty else { throw AIModifierError.emptyResponse }
            return result
        }

        throw AIModifierError.missingAPIKeys
    }

    private func callGroq(systemPrompt: String, userPrompt: String, temperature: Double, apiKey: String) async throws -> String {
        var request = URLRequest(url: AIProvider.groq.url)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let payload = GroqChatRequest(
            model: AIProvider.groq.model,
            messages: [
                GroqMessage(role: "system", content: systemPrompt),
                GroqMessage(role: "user", content: userPrompt)
            ],
            temperature: temperature
        )
        request.httpBody = try JSONEncoder().encode(payload)

        let data = try await validatedData(for: request)
        let response = try JSONDecoder().decode(GroqChatResponse.self, from: data)
        let output = response.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !output.isEmpty else { throw AIModifierError.emptyResponse }
        return output
    }

    private func callGemini(systemPrompt: String, userPrompt: String, apiKey: String) async throws -> String {
        var components = URLComponents(url: AIProvider.gemini.url, resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "key", value: apiKey)]
        guard let url = components?.url else { throw AIModifierError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let combined = "\(systemPrompt)\n\n\(userPrompt)"
        let payload = GeminiGenerateRequest(
            contents: [GeminiContent(parts: [GeminiPart(text: combined)])]
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

    // MARK: - Prompts

    private static let analysisSystem = """
    You are a precision pattern-recognition engine. Given a list of BEFORE → AFTER text pairs, infer the exact transformation rule and your confidence in it.

    Respond with VALID JSON ONLY in this exact shape, with no markdown fences and no extra commentary:
    {"rule": "<a clear, concise natural-language description of the transformation rule, including edge cases you noticed>", "confidence": <integer 0-100>}

    Confidence guidance:
    - 90-100: rule is unambiguous, multiple examples agree, no contradictions.
    - 70-89: rule is clear but only 1-2 examples, or minor ambiguity.
    - 40-69: pattern is plausible but examples are sparse or partially contradictory.
    - 0-39: cannot reliably determine a rule.
    """

    private static let applySystem = """
    You are a precision text transformation engine. Apply the user's transformation rule to the provided INPUT TEXT exactly. Use the BEFORE/AFTER examples as ground truth for formatting decisions.

    Output ONLY the transformed text. No preamble, no explanation, no markdown fences, no commentary.
    """

    private static func analysisPrompt(examples: [ExamplePair], refinement: String) -> String {
        var lines: [String] = []
        lines.append("Analyze the following before → after example pairs and return the transformation rule as JSON.")
        lines.append("")
        for (index, pair) in examples.enumerated() {
            lines.append("--- Example \(index + 1) ---")
            lines.append("BEFORE:")
            lines.append(pair.before)
            lines.append("AFTER:")
            lines.append(pair.after)
            lines.append("")
        }
        let trimmedRefinement = refinement.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedRefinement.isEmpty {
            lines.append("USER REFINEMENT (treat as authoritative guidance):")
            lines.append(trimmedRefinement)
            lines.append("")
        }
        lines.append("Return JSON only.")
        return lines.joined(separator: "\n")
    }

    private static func applyPrompt(rule: String, refinement: String, examples: [ExamplePair], chunk: String) -> String {
        var lines: [String] = []
        lines.append("RULE:")
        lines.append(rule)
        let trimmedRefinement = refinement.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedRefinement.isEmpty {
            lines.append("")
            lines.append("USER REFINEMENT:")
            lines.append(trimmedRefinement)
        }
        let usableExamples = examples.filter { $0.isUsable }.prefix(3)
        if !usableExamples.isEmpty {
            lines.append("")
            lines.append("EXAMPLES (ground truth):")
            for (index, pair) in usableExamples.enumerated() {
                lines.append("--- Example \(index + 1) ---")
                lines.append("BEFORE:")
                lines.append(pair.before)
                lines.append("AFTER:")
                lines.append(pair.after)
            }
        }
        lines.append("")
        lines.append("INPUT TEXT:")
        lines.append(chunk)
        lines.append("")
        lines.append("Output the transformed text only.")
        return lines.joined(separator: "\n")
    }

    // MARK: - Parsing

    static func parseLearnedPattern(from raw: String) -> LearnedPattern {
        let cleaned = stripCodeFences(raw)
        if let jsonString = extractJSONObject(from: cleaned),
           let data = jsonString.data(using: .utf8),
           let parsed = try? JSONDecoder().decode(LearnedPatternDTO.self, from: data) {
            return LearnedPattern(rule: parsed.rule, confidence: parsed.confidence)
        }
        // Fallback: heuristic parse
        let confidence = extractConfidence(from: cleaned)
        let rule = cleaned.isEmpty ? "Could not parse rule. Try Refine or add more examples." : cleaned
        return LearnedPattern(rule: rule, confidence: confidence)
    }

    private static func stripCodeFences(_ s: String) -> String {
        var t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.hasPrefix("```") {
            if let firstNewline = t.firstIndex(of: "\n") {
                t = String(t[t.index(after: firstNewline)...])
            }
            if t.hasSuffix("```") {
                t = String(t.dropLast(3))
            }
        }
        return t.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func extractJSONObject(from s: String) -> String? {
        guard let start = s.firstIndex(of: "{"),
              let end = s.lastIndex(of: "}"),
              start < end else { return nil }
        return String(s[start...end])
    }

    private static func extractConfidence(from s: String) -> Int {
        let lowered = s.lowercased()
        guard let range = lowered.range(of: #"confidence"\s*:\s*\d+"#, options: .regularExpression)
                ?? lowered.range(of: #"confidence\s*[:=]\s*\d+"#, options: .regularExpression) else {
            return 50
        }
        let chunk = lowered[range]
        let digits = chunk.compactMap { $0.isNumber ? $0 : nil }
        if let value = Int(String(digits)) { return value }
        return 50
    }

    private struct LearnedPatternDTO: Decodable {
        let rule: String
        let confidence: Int
    }
}
