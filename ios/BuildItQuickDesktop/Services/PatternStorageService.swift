import Foundation

nonisolated final class PatternStorageService: Sendable {
    static let shared = PatternStorageService()

    private let key = "savedPatternLibrary.v1"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> [SavedPattern] {
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode([SavedPattern].self, from: data) else {
            return []
        }
        return decoded
    }

    func save(_ patterns: [SavedPattern]) {
        guard let data = try? JSONEncoder().encode(patterns) else { return }
        defaults.set(data, forKey: key)
    }
}
