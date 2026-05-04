import SwiftUI

struct ToolsListView: View {
    @Bindable var viewModel: AppViewModel
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            List {
                ForEach(StepCategory.allCases, id: \.self) { category in
                    Section {
                        ForEach(category.steps, id: \.self) { stepType in
                            NavigationLink(value: stepType) {
                                Label(stepType.displayName, systemImage: stepType.icon)
                            }
                        }
                    } header: {
                        Label(category.rawValue, systemImage: category.icon)
                    }
                }
            }
            .navigationTitle("Tools")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: StepType.self) { stepType in
                ToolConfigView(stepType: stepType, viewModel: viewModel) {
                    isPresented = false
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { isPresented = false }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}
