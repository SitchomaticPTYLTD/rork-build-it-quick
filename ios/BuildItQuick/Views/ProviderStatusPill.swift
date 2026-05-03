import SwiftUI

struct ProviderStatusPill: View {
    let name: String
    let isConfigured: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: isConfigured ? "checkmark.seal.fill" : "key.slash.fill")
                .font(.caption.weight(.bold))
            Text(name)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(isConfigured ? .green : .secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background((isConfigured ? Color.green : Color.secondary).opacity(0.12), in: .capsule)
        .accessibilityLabel("\(name) \(isConfigured ? "configured" : "not configured")")
    }
}
