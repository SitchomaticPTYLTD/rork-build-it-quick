import SwiftUI

struct PatternLibrarySheet: View {
    @Bindable var viewModel: AITextMorphViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.savedPatterns.isEmpty {
                    ContentUnavailableView(
                        "No saved patterns yet",
                        systemImage: "books.vertical.fill",
                        description: Text("Analyze a pattern, then tap Save to keep it for next time.")
                    )
                } else {
                    List {
                        ForEach(viewModel.savedPatterns) { pattern in
                            Button {
                                viewModel.loadPattern(pattern)
                                dismiss()
                            } label: {
                                row(for: pattern)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    viewModel.deleteSavedPattern(pattern)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Pattern Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func row(for pattern: SavedPattern) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(pattern.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer(minLength: 6)
                confidenceBadge(pattern.confidence)
            }
            Text(pattern.rule)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            HStack(spacing: 10) {
                Label("\(pattern.examples.count) example\(pattern.examples.count == 1 ? "" : "s")", systemImage: "rectangle.stack")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(pattern.lastUsedAt, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func confidenceBadge(_ confidence: Int) -> some View {
        let color: Color = confidence >= 70 ? .green : (confidence >= 40 ? .orange : .red)
        Text("\(confidence)%")
            .font(.caption.weight(.bold).monospacedDigit())
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.14), in: .capsule)
    }
}
