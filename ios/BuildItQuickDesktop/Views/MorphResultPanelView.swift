import SwiftUI

struct MorphResultPanelView: View {
    let processingMode: MorphProcessingMode
    let singleOutput: String
    let batchResults: [MorphBatchResult]
    let errorMessage: String?
    let progressCurrent: Int
    let progressTotal: Int
    let progressFraction: Double
    let successfulBatchCount: Int
    let isProcessing: Bool
    let onRetry: () -> Void
    let onCopySingle: () -> Void
    let onCopyAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            if isProcessing && processingMode == .batch {
                BatchProgressView(
                    current: progressCurrent,
                    total: progressTotal,
                    fraction: progressFraction
                )
            }

            if let errorMessage {
                MorphErrorBannerView(message: errorMessage, onRetry: onRetry)
            }

            switch processingMode {
            case .single, .pattern:
                singleResult
            case .batch:
                batchResult
            }
        }
        .padding(18)
        .morphGlassSurface(cornerRadius: 24)
        .animation(.spring(duration: 0.34, bounce: 0.18), value: batchResults)
        .animation(.spring(duration: 0.34, bounce: 0.18), value: singleOutput)
        .animation(.spring(duration: 0.34, bounce: 0.18), value: errorMessage)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 3) {
                Text(processingMode == .single ? "Transformed Result" : "Batch Results")
                    .font(.headline)
                if processingMode == .batch, !batchResults.isEmpty {
                    Text("\(successfulBatchCount)/\(batchResults.count) succeeded")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if processingMode == .single, !singleOutput.isEmpty {
                Button(action: onCopySingle) {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            if processingMode == .batch, !batchResults.isEmpty {
                Button(action: onCopyAll) {
                    Label("Copy All", systemImage: "doc.on.doc.fill")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }

    @ViewBuilder
    private var singleResult: some View {
        if !singleOutput.isEmpty {
            Text(singleOutput)
                .font(.body)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(18)
                .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 18))
                .overlay {
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(.primary.opacity(0.08), lineWidth: 1)
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
        } else if errorMessage == nil {
            MorphEmptyStateView(
                title: "Ready to morph",
                systemImage: "arrow.left.and.right.circle.fill",
                message: "Choose a style, paste text, and your transformed result will appear here."
            )
        }
    }

    @ViewBuilder
    private var batchResult: some View {
        if !batchResults.isEmpty {
            LazyVStack(spacing: 14) {
                ForEach(Array(batchResults.enumerated()), id: \.element.id) { index, result in
                    MorphBatchResultCardView(index: index + 1, result: result)
                }
            }
        } else if errorMessage == nil {
            MorphEmptyStateView(
                title: "Batch results",
                systemImage: "square.stack.3d.up.fill",
                message: "Separate text blocks with blank lines to process them one by one."
            )
        }
    }
}
