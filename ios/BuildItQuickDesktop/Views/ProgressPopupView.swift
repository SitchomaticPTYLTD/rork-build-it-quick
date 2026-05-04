import SwiftUI

struct ProgressPopupView: View {
    let current: Int
    let total: Int
    let label: String

    var body: some View {
        VStack(spacing: 16) {
            ProgressView(value: Double(current), total: Double(max(total, 1)))
                .tint(.blue)

            HStack {
                Text(label)
                    .font(.subheadline.bold())
                Spacer()
                Text("\(current)/\(total)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(.rect(cornerRadius: 16))
        .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
        .padding(.horizontal, 40)
    }
}
