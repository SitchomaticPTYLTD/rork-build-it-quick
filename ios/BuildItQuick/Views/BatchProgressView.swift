import SwiftUI

struct BatchProgressView: View {
    let current: Int
    let total: Int
    let fraction: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Batch running", systemImage: "bolt.horizontal.circle.fill")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(current)/\(total)")
                    .font(.caption.monospacedDigit().weight(.bold))
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: fraction)
                .progressViewStyle(.linear)
                .tint(.indigo)
                .accessibilityLabel("Batch progress")
                .accessibilityValue("\(current) of \(total)")
        }
        .padding(14)
        .background(Color.indigo.opacity(0.10), in: .rect(cornerRadius: 16))
    }
}
