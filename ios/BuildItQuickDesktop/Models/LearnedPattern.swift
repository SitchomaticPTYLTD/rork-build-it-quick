import Foundation

nonisolated struct LearnedPattern: Codable, Equatable, Hashable, Sendable {
    var rule: String
    var confidence: Int

    init(rule: String, confidence: Int) {
        self.rule = rule
        self.confidence = max(0, min(100, confidence))
    }
}
