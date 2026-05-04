import Foundation

nonisolated enum MorphBatchStatus: Equatable, Sendable {
    case success
    case failed(String)

    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }

    var accessibilityLabel: String {
        switch self {
        case .success:
            "Successfully transformed"
        case .failed(let message):
            "Failed: \(message)"
        }
    }
}
