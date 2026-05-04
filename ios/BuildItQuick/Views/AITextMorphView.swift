import SwiftUI

struct AITextMorphView: View {
    @State private var viewModel = AITextMorphViewModel()
    @State private var showCustomModeSheet: Bool = false
    @State private var showAPIKeysSheet: Bool = false
    @State private var showPatternLibrary: Bool = false
    @State private var showSavePatternSheet: Bool = false

    var body: some View {
        @Bindable var model = viewModel

        NavigationStack {
            ZStack(alignment: .bottom) {
                MorphBackdropView()

                ScrollView {
                    LazyVStack(spacing: 18) {
                        MorphHeroHeaderView(
                            groqConfigured: !viewModel.groqKeyDraft.isEmpty,
                            geminiConfigured: !viewModel.geminiKeyDraft.isEmpty
                        )

                        MorphProcessingPickerView(processingMode: $model.processingMode)

                        if viewModel.processingMode == .pattern {
                            PatternLearnSectionView(
                                viewModel: viewModel,
                                onShowLibrary: { showPatternLibrary = true },
                                onShowSave: { showSavePatternSheet = true }
                            )
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        } else {
                            classicMorphSection
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 18)
                    .padding(.bottom, 110)
                    .animation(.spring(duration: 0.4, bounce: 0.18), value: viewModel.processingMode)
                }
                .scrollDismissesKeyboard(.interactively)

                MorphToastView(isVisible: viewModel.showCopiedToast)
                    .padding(.bottom, 20)
            }
            .navigationTitle("AI Text-Morph")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.loadKeyDrafts()
                        showAPIKeysSheet = true
                    } label: {
                        Image(systemName: "key.fill")
                    }
                    .accessibilityLabel("API Keys")
                }
            }
            .sheet(isPresented: $showCustomModeSheet) {
                CustomMorphModeSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $showAPIKeysSheet) {
                AIKeySettingsSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $showPatternLibrary) {
                PatternLibrarySheet(viewModel: viewModel)
            }
            .sheet(isPresented: $showSavePatternSheet) {
                SavePatternSheet(viewModel: viewModel)
            }
        }
    }

    @ViewBuilder
    private var classicMorphSection: some View {
        @Bindable var model = viewModel

        MorphInputCardView(
            input: $model.input,
            processingMode: viewModel.processingMode,
            characterCount: viewModel.input.count,
            wordCount: viewModel.wordCount,
            batchItemsCount: viewModel.batchItemsCount
        )

        MorphModeCarouselView(
            modes: viewModel.allModes,
            selectedMode: $model.selectedMode,
            customModeIDs: Set(viewModel.customModes.map(\.id)),
            onDelete: { viewModel.deleteCustomMode($0) },
            onCreate: { showCustomModeSheet = true }
        )

        MorphActionBarView(
            isProcessing: viewModel.isProcessing,
            canProcess: viewModel.canProcess,
            processingMode: viewModel.processingMode,
            progressCurrent: viewModel.progressCurrent,
            progressTotal: viewModel.progressTotal,
            onProcess: { Task { await viewModel.processInput() } },
            onClear: { viewModel.clearAll() }
        )

        MorphResultPanelView(
            processingMode: viewModel.processingMode,
            singleOutput: viewModel.singleOutput,
            batchResults: viewModel.batchResults,
            errorMessage: viewModel.errorMessage,
            progressCurrent: viewModel.progressCurrent,
            progressTotal: viewModel.progressTotal,
            progressFraction: viewModel.progressFraction,
            successfulBatchCount: viewModel.successfulBatchCount,
            isProcessing: viewModel.isProcessing,
            onRetry: { Task { await viewModel.retry() } },
            onCopySingle: { viewModel.copySingleOutput() },
            onCopyAll: { viewModel.copyAllResults() }
        )
    }
}

#Preview {
    AITextMorphView()
}
