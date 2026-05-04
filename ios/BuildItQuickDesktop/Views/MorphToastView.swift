import SwiftUI

struct MorphToastView: View {
    let isVisible: Bool

    var body: some View {
        Text("Copied to clipboard")
            .font(.subheadline.bold())
            .foregroundStyle(.primary)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial, in: .capsule)
            .overlay(alignment: .leading) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .padding(.leading, -4)
                    .offset(x: -22)
            }
            .shadow(color: .black.opacity(0.18), radius: 18, y: 8)
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 22)
            .animation(.spring(duration: 0.34, bounce: 0.28), value: isVisible)
            .allowsHitTesting(false)
            .accessibilityHidden(!isVisible)
    }
}
