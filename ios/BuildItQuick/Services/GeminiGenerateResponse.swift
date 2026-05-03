import Foundation

nonisolated struct GeminiGenerateResponse: Decodable, Sendable {
    let candidates: [GeminiCandidate]
}
