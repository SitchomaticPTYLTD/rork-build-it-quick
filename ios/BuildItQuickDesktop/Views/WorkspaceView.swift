import SwiftUI
import UniformTypeIdentifiers

struct WorkspaceView: View {
    @Bindable var viewModel: AppViewModel
    @State private var showTools: Bool = false
    @State private var showImporter: Bool = false
    @State private var showExporter: Bool = false
    @State private var exportType: UTType = .plainText
    @State private var showClearConfirm: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                statsBar

                TextEditor(text: $viewModel.text)
                    .font(.system(.body, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 4)
                    .background(Color(.secondarySystemBackground))
                    .scrollDismissesKeyboard(.interactively)

                bottomBar
            }
            .navigationTitle("Editor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button {
                            showImporter = true
                        } label: {
                            Label("Import File", systemImage: "folder")
                        }
                        Button {
                            viewModel.pasteFromClipboard()
                        } label: {
                            Label("Paste from Clipboard", systemImage: "doc.on.clipboard")
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    } label: {
                        Image(systemName: "keyboard.chevron.compact.down")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            exportType = .plainText
                            showExporter = true
                        } label: {
                            Label("Export as TXT", systemImage: "doc.text")
                        }
                        Button {
                            exportType = .commaSeparatedText
                            showExporter = true
                        } label: {
                            Label("Export as CSV", systemImage: "tablecells")
                        }
                        Divider()
                        Button {
                            viewModel.copyToClipboard()
                        } label: {
                            Label("Copy All", systemImage: "doc.on.doc")
                        }
                        Divider()
                        Button(role: .destructive) {
                            showClearConfirm = true
                        } label: {
                            Label("Clear All", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .fileImporter(
                isPresented: $showImporter,
                allowedContentTypes: [.plainText, .commaSeparatedText],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    viewModel.loadFileContent(.success(url))
                }
            }
            .fileExporter(
                isPresented: $showExporter,
                document: TextFile(text: viewModel.text),
                contentType: exportType,
                defaultFilename: "export.\(exportType == .commaSeparatedText ? "csv" : "txt")"
            ) { _ in }
            .alert("Clear All Text?", isPresented: $showClearConfirm) {
                Button("Clear", role: .destructive) { viewModel.clearText() }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showTools) {
                ToolsListView(viewModel: viewModel, isPresented: $showTools)
            }
        }
    }

    private var statsBar: some View {
        HStack(spacing: 16) {
            Label("\(viewModel.lineCount)", systemImage: "text.alignleft")
            Label("\(viewModel.wordCount)", systemImage: "textformat.size")
            Label("\(viewModel.charCount)", systemImage: "character.cursor.ibeam")
            Spacer()
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal)
        .padding(.vertical, 6)
        .background(Color(.systemGroupedBackground))
    }

    private var bottomBar: some View {
        HStack {
            Button {
                viewModel.undo()
            } label: {
                Image(systemName: "arrow.uturn.backward")
            }
            .disabled(!viewModel.canUndo)

            Spacer()

            Button {
                showTools = true
            } label: {
                Label("Tools", systemImage: "wrench.and.screwdriver")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)

            Spacer()

            Button {
                viewModel.redo()
            } label: {
                Image(systemName: "arrow.uturn.forward")
            }
            .disabled(!viewModel.canRedo)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .background(.bar)
    }
}
