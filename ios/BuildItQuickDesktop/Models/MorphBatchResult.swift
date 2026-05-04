import Foundation

nonisolated struct MorphBatchResult: Identifiable, Equatable, Sendable {
    let id: UUID
    let original: String
    let morphed: String
    let status: MorphBatchStatus

    init(id: UUID = UUID(), original: String, morphed: String, status: MorphBatchStatus) {
        self.id = id
        self.original = original
        self.morphed = morphed
        self.status = status
    }
}
