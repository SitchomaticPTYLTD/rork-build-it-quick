import Foundation

nonisolated enum MorphProcessingMode: String, CaseIterable, Identifiable, Sendable {
    case single = "Single"
    case batch = "Batch"
    case pattern = "Pattern"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .single: "Single"
        case .batch: "Batch"
        case .pattern: "Pattern Learn"
        }
    }
}
