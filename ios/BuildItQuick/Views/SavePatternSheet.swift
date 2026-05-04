import SwiftUI

struct SavePatternSheet: View {
    @Bindable var viewModel: AITextMorphViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Pattern name") {
                    TextField("e.g. Group credentials by email", text: $name)
                        .textInputAutocapitalization(.sentences)
                }
                if let pattern = viewModel.learnedPattern {
                    Section("Learned rule") {
                        Text(pattern.rule)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                        HStack {
                            Text("Confidence")
                            Spacer()
                            Text("\(pattern.confidence)%")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Section {
                    Text("Saved patterns are stored on this device only.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Save Pattern")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        viewModel.saveCurrentPattern(name: name)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
