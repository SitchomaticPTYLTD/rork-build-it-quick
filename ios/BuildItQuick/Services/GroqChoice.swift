import Foundation

nonisolated struct GroqChoice: Decodable, Sendable {
    let message: GroqMessage
}
