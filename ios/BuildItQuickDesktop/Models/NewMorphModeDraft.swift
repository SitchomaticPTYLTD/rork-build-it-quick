import Foundation

nonisolated struct NewMorphModeDraft: Equatable, Sendable {
    var label: String = ""
    var icon: String = "wand.and.stars"
    var prompt: String = ""

    var canSave: Bool {
        !label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
