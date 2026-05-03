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
