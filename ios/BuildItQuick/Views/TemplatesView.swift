import SwiftUI
import UniformTypeIdentifiers

struct TemplatesView: View {
    @Bindable var viewModel: AppViewModel
    @State private var showNewTemplate: Bool = false
    @State private var editingTemplate: LineRemovalTemplate? = nil
    @State private var showExporter: Bool = false
    @State private var showImporter: Bool = false
    @State private var importedCount: Int? = nil

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.templates.isEmpty {
                    ContentUnavailableView(
                        "No Templates",
                        systemImage: "bookmark",
                        description: Text("Save sets of strings for quick line removal.\nUp to 200 strings per template.")
                    )
                } else {
                    List {
                        ForEach(viewModel.templates) { template in
                            Button {
                                editingTemplate = template
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(template.name)
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                        let activeCount = template.strings.filter { !$0.isEmpty }.count
                                        Text("\(activeCount) string\(activeCount == 1 ? "" : "s")")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Button {
                                        viewModel.applyTemplate(template)
                                    } label: {
                                        Image(systemName: "play.circle.fill")
                                            .font(.title2)
                                            .foregroundStyle(.blue)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete { offsets in
                            viewModel.deleteTemplate(at: offsets)
                        }
                    }
                }
            }
            .navigationTitle("Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button {
                            showImporter = true
                        } label: {
                            Label("Import Templates", systemImage: "square.and.arrow.down")
                        }
                        if !viewModel.templates.isEmpty {
                            Button {
                                showExporter = true
                            } label: {
                                Label("Export Templates", systemImage: "square.and.arrow.up")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showNewTemplate = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showNewTemplate) {
                TemplateEditorView(template: LineRemovalTemplate()) { newTemplate in
                    viewModel.addTemplate(newTemplate)
                }
            }
            .sheet(item: $editingTemplate) { template in
                TemplateEditorView(template: template) { updated in
                    viewModel.updateTemplate(updated)
                }
            }
            .fileExporter(
                isPresented: $showExporter,
                document: ExportFile(data: viewModel.exportTemplatesData() ?? Data()),
                contentType: .json,
                defaultFilename: "templates.json"
            ) { _ in }
            .fileImporter(
                isPresented: $showImporter,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    importedCount = viewModel.importTemplates(from: url)
                }
            }
            .alert("Imported", isPresented: Binding(get: { importedCount != nil }, set: { if !$0 { importedCount = nil } })) {
                Button("OK") { importedCount = nil }
            } message: {
                Text("\(importedCount ?? 0) template\(importedCount == 1 ? "" : "s") imported successfully.")
            }
        }
    }
}
