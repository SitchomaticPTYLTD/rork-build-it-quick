import Foundation

nonisolated enum AIModifierError: LocalizedError, Sendable {
    case emptyInput
    case missingAPIKeys
    case invalidURL
    case invalidResponse
    case httpStatus(Int)
    case emptyResponse
    case cancelled

    var errorDescription: String? {
        switch self {
        case .emptyInput:
            "Paste text before running a morph."
        case .missingAPIKeys:
            "Add a Groq or Gemini API key from the key button before using AI Text-Morph."
        case .invalidURL, .invalidResponse:
            "The AI service returned an unexpected response. Please try again."
        case .httpStatus(let code):
            "The AI service could not complete the request right now. Status code: \(code)."
        case .emptyResponse:
            "The AI service returned an empty result. Try a shorter input or another style."
        case .cancelled:
            "The request was cancelled."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .missingAPIKeys:
            "Open API Keys and save at least one provider key. Groq is tried first; Gemini is used as the silent fallback."
        default:
            "Check your connection and try again."
        }
    }
}
