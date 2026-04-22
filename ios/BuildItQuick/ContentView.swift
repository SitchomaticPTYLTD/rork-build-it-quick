import SwiftUI

struct ContentView: View {
    @State private var viewModel = AppViewModel()

    var body: some View {
        ZStack {
            TabView {
                Tab("Editor", systemImage: "doc.text.fill") {
                    WorkspaceView(viewModel: viewModel)
                }
                Tab("Spreadsheet", systemImage: "tablecells.fill") {
                    SpreadsheetView(viewModel: viewModel)
                }
                Tab("Scripts", systemImage: "list.number") {
                    ScriptsView(viewModel: viewModel)
                }
                Tab("Templates", systemImage: "bookmark.fill") {
                    TemplatesView(viewModel: viewModel)
                }
            }

            if viewModel.isProcessing {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .allowsHitTesting(true)

                ProgressPopupView(
                    current: viewModel.progressCurrent,
                    total: viewModel.progressTotal,
                    label: viewModel.progressLabel
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3), value: viewModel.isProcessing)
    }
}
