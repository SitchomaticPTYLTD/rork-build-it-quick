import Foundation

nonisolated struct GeminiGenerateRequest: Encodable, Sendable {
    let contents: [GeminiContent]
}
