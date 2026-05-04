import SwiftUI

struct TemplateEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var template: LineRemovalTemplate
    @State private var showBulkImport: Bool = false
    let onSave: (LineRemovalTemplate) -> Void

    init(template: LineRemovalTemplate, onSave: @escaping (LineRemovalTemplate) -> Void) {
        self._template = State(initialValue: template)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Template Name") {
                    TextField("Name", text: $template.name)
                }

                Section {
                    ForEach(Array(template.strings.enumerated()), id: \.offset) { index, _ in
                        HStack {
                            Text("\(index + 1)")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                                .frame(width: 28, alignment: .trailing)

                            TextField("String \(index + 1)", text: Binding(
                                get: { template.strings.indices.contains(index) ? template.strings[index] : "" },
                                set: { if template.strings.indices.contains(index) { template.strings[index] = $0 } }
                            ))
                            .font(.system(.body, design: .monospaced))

                            if template.strings.count > 1 {
                                Button(role: .destructive) {
                                    template.strings.remove(at: index)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    if template.strings.count < 200 {
                        Button {
                            template.strings.append("")
                        } label: {
                            Label("Add String (\(template.strings.count)/200)", systemImage: "plus.circle")
                        }
                    }
                } header: {
                    Text("Strings (\(template.strings.filter { !$0.isEmpty }.count) active)")
                } footer: {
                    Text("Lines containing any of these strings will be removed when applied.")
                }

                Section {
                    Button {
                        showBulkImport = true
                    } label: {
                        Label("Bulk Import", systemImage: "doc.on.clipboard")
                    }
                }
            }
            .navigationTitle(template.name.isEmpty ? "New Template" : template.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(template)
                        dismiss()
                    }
                    .disabled(template.name.isEmpty)
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
            .sheet(isPresented: $showBulkImport) {
                BulkImportSheet(existingCount: template.strings.filter({ !$0.isEmpty }).count) { imported in
                    let nonEmpty = imported.filter { !$0.isEmpty }
                    let existingActive = template.strings.filter { !$0.isEmpty }
                    let combined = existingActive + nonEmpty
                    let capped = Array(combined.prefix(200))
                    template.strings = capped.isEmpty ? [""] : capped
                }
            }
        }
    }
}
