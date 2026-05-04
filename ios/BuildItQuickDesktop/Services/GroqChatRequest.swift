import Foundation

nonisolated struct GroqChatRequest: Encodable, Sendable {
    let model: String
    let messages: [GroqMessage]
    let temperature: Double
}
