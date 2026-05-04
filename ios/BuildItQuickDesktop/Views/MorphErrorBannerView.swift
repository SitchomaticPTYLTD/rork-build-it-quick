import SwiftUI

struct MorphErrorBannerView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Couldn’t complete morph")
                        .font(.subheadline.bold())
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }

            Button(action: onRetry) {
                Label("Retry", systemImage: "arrow.clockwise")
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .tint(.indigo)
        }
        .padding(14)
        .background(Color.red.opacity(0.10), in: .rect(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.red.opacity(0.18), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}
