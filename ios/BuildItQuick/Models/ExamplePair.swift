import Foundation

nonisolated struct ExamplePair: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: UUID
    var before: String
    var after: String

    init(id: UUID = UUID(), before: String = "", after: String = "") {
        self.id = id
        self.before = before
        self.after = after
    }

    var isUsable: Bool {
        !before.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && !after.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
