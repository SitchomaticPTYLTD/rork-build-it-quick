import SwiftUI

struct PatternConfidenceRingView: View {
    let confidence: Int
    var diameter: CGFloat = 96

    @State private var animatedFraction: Double = 0

    private var fraction: Double { Double(confidence) / 100.0 }

    private var color: Color {
        switch confidence {
        case 0..<40: return .red
        case 40..<70: return .orange
        default: return .green
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.18), lineWidth: 10)
            Circle()
                .trim(from: 0, to: animatedFraction)
                .stroke(
                    LinearGradient(colors: [color, color.opacity(0.55)], startPoint: .top, endPoint: .bottom),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            VStack(spacing: 1) {
                Text("\(confidence)")
                    .font(.title2.bold().monospacedDigit())
                    .contentTransition(.numericText(value: Double(confidence)))
                Text("%")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: diameter, height: diameter)
        .onAppear {
            withAnimation(.spring(duration: 0.9, bounce: 0.18)) {
                animatedFraction = fraction
            }
        }
        .onChange(of: confidence) { _, _ in
            withAnimation(.spring(duration: 0.7, bounce: 0.2)) {
                animatedFraction = fraction
            }
        }
        .accessibilityLabel("Confidence \(confidence) percent")
    }
}
