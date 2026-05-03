import Foundation

nonisolated struct GeminiContent: Codable, Sendable {
    let parts: [GeminiPart]
}
