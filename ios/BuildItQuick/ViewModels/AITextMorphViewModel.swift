import Foundation
import UIKit

@Observable
@MainActor
final class AITextMorphViewModel {
    var input: String = ""
    var singleOutput: String = ""
    var batchResults: [MorphBatchResult] = []
    var selectedMode: MorphMode = MorphMode.presets[0]
    var processingMode: MorphProcessingMode = .single
    var customModes: [MorphMode] = []
    var newModeDraft: NewMorphModeDraft = NewMorphModeDraft()
    var isProcessing: Bool = false
    var progressCurrent: Int = 0
    var progressTotal: Int = 0
    var errorMessage: String? = nil
    var showCopiedToast: Bool = false
    var groqKeyDraft: String = ""
    var geminiKeyDraft: String = ""

    private let service: AIModifierService
    private let keychain: AIKeychainStore
    private let customModesKey = "customMorphModes"

    init(
        service: AIModifierService = AIModifierService(),
        keychain: AIKeychainStore = .shared
    ) {
        self.service = service
        self.keychain = keychain
        loadCustomModes()
        loadKeyDrafts()
    }

    var allModes: [MorphMode] {
        MorphMode.presets + customModes
    }

    var wordCount: Int {
        input.split { $0.isWhitespace || $0.isNewline }.count
    }

    var batchItems: [String] {
        input
            .components(separatedBy: CharacterSet.newlines)
            .reduce(into: [String]()) { groups, line in
                let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmedLine.isEmpty {
                    if groups.last?.isEmpty == false { groups.append("") }
                } else if groups.isEmpty || groups.last?.isEmpty == true {
                    if groups.last?.isEmpty == true { groups.removeLast() }
                    groups.append(line)
                } else {
                    groups[groups.count - 1] += "\n\(line)"
                }
            }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    var batchItemsCount: Int {
        batchItems.count
    }

    var hasOutput: Bool {
        !singleOutput.isEmpty || !batchResults.isEmpty
    }

    var canProcess: Bool {
        !isProcessing && !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var progressFraction: Double {
        guard progressTotal > 0 else { return 0 }
        return Double(progressCurrent) / Double(progressTotal)
    }

    var successfulBatchCount: Int {
        batchResults.filter { $0.status.isSuccess }.count
    }

    func loadCustomModes() {
        guard let data = UserDefaults.standard.data(forKey: customModesKey),
              let decoded = try? JSONDecoder().decode([MorphMode].self, from: data) else {
            customModes = []
            return
        }
        customModes = decoded
    }

    func saveCustomModes() {
        guard let data = try? JSONEncoder().encode(customModes) else { return }
        UserDefaults.standard.set(data, forKey: customModesKey)
    }

    func addCustomMode() {
        let label = newModeDraft.label.trimmingCharacters(in: .whitespacesAndNewlines)
        let prompt = newModeDraft.prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let icon = normalizedIcon(newModeDraft.icon)
        guard !label.isEmpty, !prompt.isEmpty else { return }

        let mode = MorphMode(
            id: "custom-\(UUID().uuidString)",
            label: label,
            icon: icon,
            prompt: prompt
        )
        customModes.append(mode)
        saveCustomModes()
        selectedMode = mode
        newModeDraft = NewMorphModeDraft()
    }

    func deleteCustomMode(_ mode: MorphMode) {
        customModes.removeAll { $0.id == mode.id }
        saveCustomModes()
        if selectedMode.id == mode.id {
            selectedMode = MorphMode.presets[0]
        }
    }

    func processInput() async {
        guard canProcess else { return }
        isProcessing = true
        errorMessage = nil
        singleOutput = ""
        batchResults = []
        progressCurrent = 0
        progressTotal = processingMode == .batch ? batchItems.count : 1

        defer { isProcessing = false }

        switch processingMode {
        case .single:
            await processSingle()
        case .batch:
            await processBatch()
        }
    }

    func retry() async {
        errorMessage = nil
        await processInput()
    }

    func copySingleOutput() {
        copyToClipboard(singleOutput)
    }

    func copyAllResults() {
        let text = batchResults.enumerated().map { index, result in
            "Item \(index + 1)\nOriginal:\n\(result.original)\n\nMorphed:\n\(result.morphed)"
        }.joined(separator: "\n\n-----------------------------------\n\n")
        copyToClipboard(text)
    }

    func clearAll() {
        input = ""
        singleOutput = ""
        batchResults = []
        errorMessage = nil
        progressCurrent = 0
        progressTotal = 0
    }

    func loadKeyDrafts() {
        groqKeyDraft = keychain.read(AIProvider.groq.keychainAccount)
        geminiKeyDraft = keychain.read(AIProvider.gemini.keychainAccount)
    }

    func saveAPIKeys() {
        keychain.save(groqKeyDraft, account: AIProvider.groq.keychainAccount)
        keychain.save(geminiKeyDraft, account: AIProvider.gemini.keychainAccount)
        loadKeyDrafts()
    }

    private func processSingle() async {
        do {
            progressCurrent = 1
            singleOutput = try await service.process(text: input, mode: selectedMode)
        } catch {
            errorMessage = friendlyMessage(for: error)
        }
    }

    private func processBatch() async {
        let items = batchItems
        guard !items.isEmpty else {
            errorMessage = "Separate batch items with a blank line, then try again."
            return
        }

        var results: [MorphBatchResult] = []
        for (index, item) in items.enumerated() {
            progressCurrent = index + 1
            do {
                let morphed = try await service.process(text: item, mode: selectedMode)
                results.append(MorphBatchResult(original: item, morphed: morphed, status: .success))
            } catch {
                results.append(MorphBatchResult(original: item, morphed: "Could not process this item.", status: .failed(friendlyMessage(for: error))))
            }
            batchResults = results
        }
    }

    private func friendlyMessage(for error: Error) -> String {
        if let modifierError = error as? AIModifierError {
            return modifierError.errorDescription ?? "AI Text-Morph could not finish this request."
        }
        if error is CancellationError {
            return "The request was cancelled."
        }
        return "Failed to connect. Check your network and API keys, then try again."
    }

    private func normalizedIcon(_ rawValue: String) -> String {
        let trimmedValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedValue.isEmpty ? "wand.and.stars" : trimmedValue
    }

    private func copyToClipboard(_ text: String) {
        guard !text.isEmpty else { return }
        UIPasteboard.general.string = text
        showCopiedToast = true
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.8))
            showCopiedToast = false
        }
    }
}
