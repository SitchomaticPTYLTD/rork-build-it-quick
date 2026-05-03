import SwiftUI

struct MorphInputCardView: View {
    @Binding var input: String
    let processingMode: MorphProcessingMode
    let characterCount: Int
    let wordCount: Int
    let batchItemsCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Label(processingMode == .single ? "Input" : "Batch Input", systemImage: "text.quote")
                    .font(.headline)
                Spacer()
                Text(counterText)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            ZStack(alignment: .topLeading) {
                TextEditor(text: $input)
                    .font(.body)
                    .frame(minHeight: 210)
                    .scrollContentBackground(.hidden)
                    .padding(12)
                    .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 18))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18)
                            .strokeBorder(.primary.opacity(0.08), lineWidth: 1)
                    }
                    .accessibilityLabel(processingMode == .single ? "Text to morph" : "Batch texts to morph")

                if input.isEmpty {
                    Text(placeholder)
                        .font(.body)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 17)
                        .padding(.vertical, 20)
                        .allowsHitTesting(false)
                }
            }

            Label(helpText, systemImage: processingMode == .single ? "keyboard" : "rectangle.stack.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .morphGlassSurface(cornerRadius: 24)
    }

    private var counterText: String {
        switch processingMode {
        case .single:
            "\(characterCount) chars • \(wordCount) words"
        case .batch:
            "\(batchItemsCount) item\(batchItemsCount == 1 ? "" : "s")"
        }
    }

    private var placeholder: String {
        switch processingMode {
        case .single:
            "Paste the text you want transformed..."
        case .batch:
            "Paste multiple text blocks. Separate each item with one blank line..."
        }
    }

    private var helpText: String {
        switch processingMode {
        case .single:
            "Single mode transforms the entire input as one polished result."
        case .batch:
            "Batch mode keeps each blank-line-separated item independent."
        }
    }
}
