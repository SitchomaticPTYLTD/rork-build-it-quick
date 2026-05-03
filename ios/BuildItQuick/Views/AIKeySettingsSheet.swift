import SwiftUI

struct AIKeySettingsSheet: View {
    @Bindable var viewModel: AITextMorphViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("Groq API key", text: $viewModel.groqKeyDraft)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textContentType(.password)
                    SecureField("Gemini API key", text: $viewModel.geminiKeyDraft)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textContentType(.password)
                } header: {
                    Text("Provider Keys")
                } footer: {
                    Text("Keys are stored in Keychain. Groq is tried first; Gemini is used silently if Groq fails. Leave a field blank to remove that key.")
                }

                Section("Status") {
                    Label(viewModel.groqKeyDraft.isEmpty ? "Groq key not configured" : "Groq key ready", systemImage: viewModel.groqKeyDraft.isEmpty ? "key.slash" : "checkmark.seal.fill")
                    Label(viewModel.geminiKeyDraft.isEmpty ? "Gemini fallback not configured" : "Gemini fallback ready", systemImage: viewModel.geminiKeyDraft.isEmpty ? "key.slash" : "checkmark.seal.fill")
                }
            }
            .navigationTitle("AI API Keys")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.loadKeyDrafts()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.saveAPIKeys()
                        dismiss()
                    }
                }
            }
            .presentationDetents([.medium, .large])
            .presentationContentInteraction(.scrolls)
        }
    }
}
