import SwiftUI

struct MorphBatchResultCardView: View {
    let index: Int
    let result: MorphBatchResult

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Text("ITEM \(index)")
                    .font(.caption.monospacedDigit().weight(.black))
                    .foregroundStyle(.secondary)
                Spacer()
                statusPill
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Original")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                Text(result.original)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .textSelection(.enabled)
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text("Morphed")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(result.status.isSuccess ? .green : .red)
                Text(result.morphed)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(borderColor, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Item \(index), \(result.status.accessibilityLabel)")
    }

    private var statusPill: some View {
        HStack(spacing: 5) {
            Image(systemName: result.status.isSuccess ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
            Text(result.status.isSuccess ? "Done" : "Failed")
        }
        .font(.caption.weight(.bold))
        .foregroundStyle(result.status.isSuccess ? .green : .red)
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background((result.status.isSuccess ? Color.green : Color.red).opacity(0.12), in: .capsule)
    }

    private var borderColor: Color {
        (result.status.isSuccess ? Color.green : Color.red).opacity(0.18)
    }
}
