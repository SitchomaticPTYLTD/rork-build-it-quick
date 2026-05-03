import SwiftUI

struct MorphEmptyStateView: View {
    let title: String
    let systemImage: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 42, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.indigo)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 290)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 34)
        .padding(.horizontal, 16)
        .background(Color(.secondarySystemGroupedBackground).opacity(0.72), in: .rect(cornerRadius: 18))
        .accessibilityElement(children: .combine)
    }
}
