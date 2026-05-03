import Foundation

nonisolated struct GeminiCandidate: Decodable, Sendable {
    let content: GeminiContent
}
