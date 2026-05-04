import Foundation
import UIKit

@Observable
@MainActor
final class AITextMorphViewModel {
    // MARK: - Existing morph state
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

    // MARK: - Pattern Learn state
    var examples: [ExamplePair] = [
        ExamplePair(),
        ExamplePair()
    ]
    var refinement: String = ""
    var learnedPattern: LearnedPattern?
    var isAnalyzing: Bool = false
    var analyzeError: String?

    var bulkInput: String = ""
    var bulkOutput: String = ""
    var isApplying: Bool = false
    var applyProgressCurrent: Int = 0
    var applyProgressTotal: Int = 0
    var applyError: String?
    private var applyTask: Task<Void, Never>?

    var savedPatterns: [SavedPattern] = []

    private let service: AIModifierService
    private let patternService: PatternLearningService
    private let patternStorage: PatternStorageService
    private let keychain: AIKeychainStore
    private let customModesKey = "customMorphModes"

    init(
        service: AIModifierService = AIModifierService(),
        patternService: PatternLearningService = PatternLearningService(),
        patternStorage: PatternStorageService = .shared,
        keychain: AIKeychainStore = .shared
    ) {
        self.service = service
        self.patternService = patternService
        self.patternStorage = patternStorage
        self.keychain = keychain
        loadCustomModes()
        loadKeyDrafts()
        loadSavedPatterns()
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

    // MARK: - Pattern derived

    var usableExamplesCount: Int {
        examples.filter { $0.isUsable }.count
    }

    var canAnalyze: Bool {
        !isAnalyzing && usableExamplesCount >= 1
    }

    var canApplyPattern: Bool {
        !isApplying
        && learnedPattern != nil
        && !bulkInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var bulkInputLineCount: Int {
        let trimmed = bulkInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return 0 }
        return trimmed.components(separatedBy: .newlines).count
    }

    var bulkOutputLineCount: Int {
        let trimmed = bulkOutput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return 0 }
        return trimmed.components(separatedBy: .newlines).count
    }

    var applyProgressFraction: Double {
        guard applyProgressTotal > 0 else { return 0 }
        return Double(applyProgressCurrent) / Double(applyProgressTotal)
    }

    // MARK: - Custom mode persistence

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

    // MARK: - Process (Single / Batch)

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
        case .single, .pattern:
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

    // MARK: - Pattern Learn methods

    func addExamplePair() {
        examples.append(ExamplePair())
    }

    func removeExample(_ pair: ExamplePair) {
        examples.removeAll { $0.id == pair.id }
        if examples.isEmpty {
            examples = [ExamplePair()]
        }
    }

    func duplicateExample(_ pair: ExamplePair) {
        guard let index = examples.firstIndex(where: { $0.id == pair.id }) else { return }
        let copy = ExamplePair(before: pair.before, after: pair.after)
        examples.insert(copy, at: index + 1)
    }

    func clearExamples() {
        examples = [ExamplePair(), ExamplePair()]
        learnedPattern = nil
        analyzeError = nil
        refinement = ""
    }

    func applyTemplate(_ template: PatternTemplate) {
        examples = template.examples
        refinement = ""
        learnedPattern = nil
        analyzeError = nil
    }

    func analyzeExamples() async {
        guard canAnalyze else { return }
        isAnalyzing = true
        analyzeError = nil
        defer { isAnalyzing = false }

        let usable = examples.filter { $0.isUsable }
        guard !usable.isEmpty else {
            analyzeError = "Add at least one full before → after pair."
            return
        }
        do {
            let pattern = try await patternService.analyze(examples: usable, refinement: refinement)
            learnedPattern = pattern
        } catch {
            analyzeError = friendlyMessage(for: error)
        }
    }

    func cancelApply() {
        applyTask?.cancel()
        applyTask = nil
        isApplying = false
    }

    func applyPattern() {
        guard canApplyPattern, let pattern = learnedPattern else { return }
        applyTask?.cancel()

        let chunks = chunkBulkInput(bulkInput, linesPerChunk: 60)
        guard !chunks.isEmpty else { return }

        bulkOutput = ""
        applyError = nil
        applyProgressCurrent = 0
        applyProgressTotal = chunks.count
        isApplying = true

        let usableExamples = examples.filter { $0.isUsable }
        let rule = pattern.rule
        let refine = refinement
        let service = patternService

        applyTask = Task { [weak self] in
            var collected: [String] = []
            for (index, chunk) in chunks.enumerated() {
                if Task.isCancelled { break }
                do {
                    let transformed = try await service.apply(
                        rule: rule,
                        refinement: refine,
                        examples: usableExamples,
                        chunk: chunk
                    )
                    collected.append(transformed)
                    guard let self else { return }
                    self.applyProgressCurrent = index + 1
                    self.bulkOutput = collected.joined(separator: "\n")
                } catch is CancellationError {
                    break
                } catch {
                    guard let self else { return }
                    self.applyError = self.friendlyMessage(for: error)
                    break
                }
            }
            guard let self else { return }
            self.isApplying = false
            self.applyTask = nil
        }
    }

    func copyBulkOutput() {
        copyToClipboard(bulkOutput)
    }

    func clearBulk() {
        bulkInput = ""
        bulkOutput = ""
        applyError = nil
        applyProgressCurrent = 0
        applyProgressTotal = 0
    }

    // MARK: - Pattern library

    func loadSavedPatterns() {
        savedPatterns = patternStorage.load().sorted { $0.lastUsedAt > $1.lastUsedAt }
    }

    func saveCurrentPattern(name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, let pattern = learnedPattern else { return }
        let usable = examples.filter { $0.isUsable }
        let saved = SavedPattern(
            name: trimmedName,
            rule: pattern.rule,
            confidence: pattern.confidence,
            examples: usable,
            refinement: refinement
        )
        var updated = patternStorage.load()
        updated.insert(saved, at: 0)
        patternStorage.save(updated)
        loadSavedPatterns()
    }

    func loadPattern(_ saved: SavedPattern) {
        examples = saved.examples.isEmpty ? [ExamplePair()] : saved.examples
        learnedPattern = LearnedPattern(rule: saved.rule, confidence: saved.confidence)
        refinement = saved.refinement
        analyzeError = nil

        var all = patternStorage.load()
        if let index = all.firstIndex(where: { $0.id == saved.id }) {
            all[index].lastUsedAt = Date()
            patternStorage.save(all)
        }
        loadSavedPatterns()
    }

    func deleteSavedPattern(_ saved: SavedPattern) {
        var all = patternStorage.load()
        all.removeAll { $0.id == saved.id }
        patternStorage.save(all)
        loadSavedPatterns()
    }

    // MARK: - Helpers

    private func chunkBulkInput(_ text: String, linesPerChunk: Int) -> [String] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        let lines = trimmed.components(separatedBy: .newlines)
        guard lines.count > linesPerChunk else { return [trimmed] }
        var chunks: [String] = []
        var index = 0
        while index < lines.count {
            let end = min(index + linesPerChunk, lines.count)
            let slice = lines[index..<end].joined(separator: "\n")
            chunks.append(slice)
            index = end
        }
        return chunks
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
