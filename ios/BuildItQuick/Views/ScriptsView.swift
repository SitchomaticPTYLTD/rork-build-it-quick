import SwiftUI
import UniformTypeIdentifiers

struct ScriptsView: View {
    @Bindable var viewModel: AppViewModel
    @State private var showNewScript: Bool = false
    @State private var editingScript: ScriptTemplate? = nil
    @State private var showExporter: Bool = false
    @State private var showImporter: Bool = false
    @State private var importedCount: Int? = nil

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.scripts.isEmpty {
                    ContentUnavailableView(
                        "No Scripts",
                        systemImage: "list.number",
                        description: Text("Create reusable processing pipelines.\nEach script is a sequence of tools that run in order.")
                    )
                } else {
                    List {
                        ForEach(viewModel.scripts) { script in
                            Button {
                                editingScript = script
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(script.name)
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                        Text("\(script.steps.count) step\(script.steps.count == 1 ? "" : "s")")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Button {
                                        viewModel.runScript(script)
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
                            viewModel.deleteScript(at: offsets)
                        }
                    }
                }
            }
            .navigationTitle("Scripts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button {
                            showImporter = true
                        } label: {
                            Label("Import Scripts", systemImage: "square.and.arrow.down")
                        }
                        if !viewModel.scripts.isEmpty {
                            Button {
                                showExporter = true
                            } label: {
                                Label("Export Scripts", systemImage: "square.and.arrow.up")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showNewScript = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showNewScript) {
                ScriptEditorView(viewModel: viewModel, script: ScriptTemplate()) { newScript in
                    viewModel.addScript(newScript)
                }
            }
            .sheet(item: $editingScript) { script in
                ScriptEditorView(viewModel: viewModel, script: script) { updated in
                    viewModel.updateScript(updated)
                }
            }
            .fileExporter(
                isPresented: $showExporter,
                document: ExportFile(data: viewModel.exportScriptsData() ?? Data()),
                contentType: .json,
                defaultFilename: "scripts.json"
            ) { _ in }
            .fileImporter(
                isPresented: $showImporter,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    importedCount = viewModel.importScripts(from: url)
                }
            }
            .alert("Imported", isPresented: Binding(get: { importedCount != nil }, set: { if !$0 { importedCount = nil } })) {
                Button("OK") { importedCount = nil }
            } message: {
                Text("\(importedCount ?? 0) script\(importedCount == 1 ? "" : "s") imported successfully.")
            }
        }
    }
}
