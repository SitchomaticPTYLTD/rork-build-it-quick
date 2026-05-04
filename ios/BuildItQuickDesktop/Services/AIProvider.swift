import Foundation

nonisolated enum AIProvider: Sendable {
    case groq
    case gemini

    var keychainAccount: String {
        switch self {
        case .groq: "groq-api-key"
        case .gemini: "gemini-api-key"
        }
    }

    /// Falls back to the public env var (Config) when no key is stored in Keychain.
    var envFallbackKey: String {
        switch self {
        case .groq: Config.EXPO_PUBLIC_GROQ_API_KEY
        case .gemini: Config.EXPO_PUBLIC_GEMINI_API_KEY
        }
    }

    /// Resolves the active API key, preferring user-supplied Keychain values over env defaults.
    func resolvedKey(keychain: AIKeychainStore) -> String {
        let stored = keychain.read(keychainAccount).trimmingCharacters(in: .whitespacesAndNewlines)
        if !stored.isEmpty { return stored }
        return envFallbackKey.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var displayName: String {
        switch self {
        case .groq: "Groq"
        case .gemini: "Gemini"
        }
    }

    var model: String {
        switch self {
        case .groq: "llama-3.3-70b-versatile"
        case .gemini: "gemini-1.5-flash"
        }
    }

    var url: URL {
        switch self {
        case .groq:
            URL(string: "https://api.groq.com/openai/v1/chat/completions")!
        case .gemini:
            URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent")!
        }
    }
}
