import Foundation

nonisolated struct GroqChatResponse: Decodable, Sendable {
    let choices: [GroqChoice]
}
