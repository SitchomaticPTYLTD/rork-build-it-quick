import SwiftUI

struct MorphActionBarView: View {
    let isProcessing: Bool
    let canProcess: Bool
    let processingMode: MorphProcessingMode
    let progressCurrent: Int
    let progressTotal: Int
    let onProcess: () -> Void
    let onClear: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onProcess) {
                HStack(spacing: 10) {
                    if isProcessing {
                        ProgressView()
                            .tint(.white)
                        Text(progressText)
                            .font(.headline.monospacedDigit())
                    } else {
                        Image(systemName: "sparkles")
                        Text(processingMode == .single ? "MORPH TEXT" : "MORPH ALL")
                            .font(.headline.weight(.black))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(Color.primary, in: .rect(cornerRadius: 18))
                .foregroundStyle(Color(.systemBackground))
            }
            .buttonStyle(.plain)
            .disabled(!canProcess)
            .opacity(canProcess ? 1 : 0.45)
            .accessibilityLabel(processingMode == .single ? "Morph text" : "Morph all batch items")

            Button(action: onClear) {
                Image(systemName: "trash.fill")
                    .font(.title3.weight(.bold))
                    .frame(width: 58, height: 58)
                    .background(Color.red.opacity(0.12), in: .rect(cornerRadius: 18))
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Clear input and results")
        }
        .sensoryFeedback(.impact, trigger: isProcessing)
    }

    private var progressText: String {
        guard processingMode == .batch, progressTotal > 0 else { return "Working" }
        return "\(progressCurrent)/\(progressTotal)"
    }
}
