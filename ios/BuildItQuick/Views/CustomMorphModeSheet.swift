import SwiftUI

struct CustomMorphModeSheet: View {
    @Bindable var viewModel: AITextMorphViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Mode name", text: $viewModel.newModeDraft.label)
                        .textInputAutocapitalization(.words)
                    TextField("Emoji or SF Symbol", text: $viewModel.newModeDraft.icon)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("Mode Details")
                } footer: {
                    Text("Use an emoji like 🔮 or an SF Symbol name like wand.and.stars.")
                }

                Section("AI Instruction") {
                    TextEditor(text: $viewModel.newModeDraft.prompt)
                        .frame(minHeight: 190)
                        .accessibilityLabel("Custom AI instruction")
                }
            }
            .navigationTitle("New Morph Style")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.newModeDraft = NewMorphModeDraft()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        viewModel.addCustomMode()
                        dismiss()
                    }
                    .disabled(!viewModel.newModeDraft.canSave)
                }
            }
            .presentationDetents([.medium, .large])
            .presentationContentInteraction(.scrolls)
        }
    }
}
