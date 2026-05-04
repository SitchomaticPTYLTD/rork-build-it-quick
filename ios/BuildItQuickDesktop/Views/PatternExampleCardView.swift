import SwiftUI

struct PatternExampleCardView: View {
    let index: Int
    @Binding var pair: ExamplePair
    let canRemove: Bool
    let onRemove: () -> Void
    let onDuplicate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text("EXAMPLE \(index)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.indigo)
                if pair.isUsable {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
                Spacer(minLength: 0)
                Menu {
                    Button {
                        onDuplicate()
                    } label: {
                        Label("Duplicate", systemImage: "plus.square.on.square")
                    }
                    Button(role: .destructive) {
                        onRemove()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .disabled(!canRemove)
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: 28)
                }
                .accessibilityLabel("Example actions")
            }

            field(title: "BEFORE", text: $pair.before, accent: Color.orange)

            HStack(spacing: 6) {
                Rectangle()
                    .fill(.secondary.opacity(0.18))
                    .frame(height: 1)
                Image(systemName: "arrow.down")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.indigo)
                Rectangle()
                    .fill(.secondary.opacity(0.18))
                    .frame(height: 1)
            }

            field(title: "AFTER", text: $pair.after, accent: Color.green)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(.primary.opacity(0.06), lineWidth: 1)
        }
    }

    @ViewBuilder
    private func field(title: String, text: Binding<String>, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption2.weight(.bold))
                .foregroundStyle(accent)
            ZStack(alignment: .topLeading) {
                TextEditor(text: text)
                    .font(.callout.monospaced())
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 64, maxHeight: 160)
                    .padding(10)
                    .background(Color(.tertiarySystemBackground), in: .rect(cornerRadius: 12))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(accent.opacity(0.18), lineWidth: 1)
                    }
                if text.wrappedValue.isEmpty {
                    Text(title == "BEFORE" ? "Original text..." : "Desired result...")
                        .font(.callout)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 18)
                        .allowsHitTesting(false)
                }
            }
        }
    }
}
