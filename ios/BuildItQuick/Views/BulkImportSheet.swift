import SwiftUI

struct BulkImportSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var pasteText: String = ""
    let existingCount: Int
    let onImport: ([String]) -> Void

    private var parsedLines: [String] {
        pasteText.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    private var availableSlots: Int {
        max(0, 50000 - existingCount)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextEditor(text: $pasteText)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 200)
                        .scrollContentBackground(.hidden)
                } header: {
                    Text("Paste strings, one per line (up to 50,000)")
                } footer: {
                    let count = parsedLines.count
                    if count > availableSlots {
                        Text("⚠ \(count) lines pasted, but only \(availableSlots) slots available. Extra lines will be trimmed.")
                            .foregroundStyle(.orange)
                    } else {
                        Text("\(count) line\(count == 1 ? "" : "s") detected · \(availableSlots) slots available")
                    }
                }

                Section {
                    Button {
                        if let content = UIPasteboard.general.string {
                            pasteText = content
                        }
                    } label: {
                        Label("Paste from Clipboard", systemImage: "doc.on.clipboard")
                    }

                    Button(role: .destructive) {
                        pasteText = ""
                    } label: {
                        Label("Clear", systemImage: "trash")
                    }
                    .disabled(pasteText.isEmpty)
                }

                Section {
                    Button {
                        let capped = Array(parsedLines.prefix(availableSlots))
                        onImport(capped)
                        dismiss()
                    } label: {
                        HStack {
                            Spacer()
                            Label("Import \(min(parsedLines.count, availableSlots)) String\(min(parsedLines.count, availableSlots) == 1 ? "" : "s")", systemImage: "square.and.arrow.down")
                                .font(.headline)
                            Spacer()
                        }
                    }
                    .disabled(parsedLines.isEmpty)
                }
            }
            .navigationTitle("Bulk Import")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    } label: {
                        Image(systemName: "keyboard.chevron.compact.down")
                    }
                }
            }
        }
    }
}
