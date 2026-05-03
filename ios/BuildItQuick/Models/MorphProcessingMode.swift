import Foundation

nonisolated enum MorphProcessingMode: String, CaseIterable, Identifiable, Sendable {
    case single = "Single"
    case batch = "Batch"

    var id: String { rawValue }
}
