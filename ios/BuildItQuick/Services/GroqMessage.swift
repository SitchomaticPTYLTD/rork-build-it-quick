import Foundation

nonisolated struct GroqMessage: Codable, Sendable {
    let role: String
    let content: String
}
