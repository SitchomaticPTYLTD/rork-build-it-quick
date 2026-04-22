import SwiftUI
import UniformTypeIdentifiers

@Observable
@MainActor
class AppViewModel {
    var text: String = ""
    var scripts: [ScriptTemplate] = []
    var templates: [LineRemovalTemplate] = []

    var isProcessing: Bool = false
    var progressCurrent: Int = 0
    var progressTotal: Int = 0
    var progressLabel: String = ""

    var bulkMergeResult: String? = nil
    var showBulkMergeExporter: Bool = false

    private var textHistory: [String] = [""]
    private var historyIndex: Int = 0

    var canUndo: Bool { historyIndex > 0 }
    var canRedo: Bool { historyIndex < textHistory.count - 1 }

    var lineCount: Int {
        text.isEmpty ? 0 : text.components(separatedBy: "\n").count
    }

    var wordCount: Int {
        let words = text.split { $0.isWhitespace || $0.isNewline }
        return words.count
    }

    var charCount: Int { text.count }

    var progressText: String {
        guard progressTotal > 0 else { return progressLabel }
        return "\(progressCurrent)/\(progressTotal) — \(progressLabel)"
    }

    init() {
        scripts = StorageService.shared.loadScripts()
        templates = StorageService.shared.loadTemplates()
        seedBuiltInScripts()
    }

    private func seedBuiltInScripts() {
        let existingNames = Set(scripts.map { $0.name })
        let builtIn = AppViewModel.builtInScripts()
        var added = false
        for script in builtIn where !existingNames.contains(script.name) {
            scripts.append(script)
            added = true
        }
        if added {
            StorageService.shared.saveScripts(scripts)
        }
    }

    private static func builtInScripts() -> [ScriptTemplate] {
        [
            ScriptTemplate(name: "Premium card types", steps: [
                ProcessingStep(type: .removeLinesNotContaining, strings: [
                    "Platinum", "Signature", "Gold", "Corporate", "Alberta",
                    "Australia", "Zealand", "Island", "Infinite", "Purchasing",
                    "Titanium", "Business", "Uhnw", "World"
                ])
            ]),
            ScriptTemplate(name: "Casino keywords", steps: [
                ProcessingStep(type: .removeLinesNotContaining, strings: [
                    "Spin", "Slot", "Vegas", "Reel", "Pokie", "fortune",
                    "Casin", "Win", "Play", "Bit", "King", "Joker", "Joka", "Bet"
                ])
            ]),
            ScriptTemplate(name: "International emails", steps: [
                ProcessingStep(type: .removeLinesContaining, strings: [
                    ".pl;", ".de;", ".cz;", ".za;", ".nz;", ".it;"
                ])
            ]),
            ScriptTemplate(name: "Convert to frequency report V2", steps: [
                ProcessingStep(type: .convertLogToDualFindData),
                ProcessingStep(type: .removeLinesContaining, strings: [":"]),
                ProcessingStep(type: .removePrefix, prefix: " \u{2022} "),
                ProcessingStep(type: .removeLinesContaining, strings: ["name/ema", "==="]),
                ProcessingStep(type: .removeEmptyLines),
                ProcessingStep(type: .replaceText, searchText: "PASSWORDS", replaceText: "\u{2014}\u{2014}\u{2014}\u{2014}\u{2014}\u{2014}\u{2014}\u{2014}\u{2014}\u{2014}\u{2014}\u{2014}\u{2014}\u{2014}\u{2014}\u{2014}\u{2014}\u{2014}\u{2014}\u{2014}\u{2014}\u{2014}\u{2014}-")
            ]),
            ScriptTemplate(name: "Remove dot point prefix", steps: [
                ProcessingStep(type: .removePrefix, prefix: " \u{2022} ")
            ])
        ]
    }

    func applyStep(_ step: ProcessingStep) {
        let lines = text.components(separatedBy: "\n")
        if lines.count > 1000 {
            isProcessing = true
            progressCurrent = 0
            progressTotal = 1
            progressLabel = "Applying \(step.type.displayName)..."
            pushHistory()
            text = TextProcessingService.apply(step, to: text)
            progressCurrent = 1
            isProcessing = false
        } else {
            pushHistory()
            text = TextProcessingService.apply(step, to: text)
        }
    }

    func applyStepAsync(_ step: ProcessingStep) async {
        pushHistory()
        isProcessing = true
        progressCurrent = 0
        progressTotal = 1
        progressLabel = "Applying \(step.type.displayName)..."

        let currentText = text
        let result: String

        switch step.type {
        case .removeLinesContaining:
            result = await TextProcessingService.removeLinesContainingAsync(
                currentText,
                strings: step.strings,
                useWildcard: step.useWildcard,
                exceptions: step.exceptions,
                clearOnly: step.clearOnly
            ) { current, total in
                Task { @MainActor in
                    self.progressCurrent = current
                    self.progressTotal = total
                    self.progressLabel = "Processing lines..."
                }
            }
        case .removeLinesNotContaining:
            result = await TextProcessingService.removeLinesNotContainingAsync(
                currentText,
                strings: step.strings,
                useWildcard: step.useWildcard,
                exceptions: step.exceptions
            ) { current, total in
                Task { @MainActor in
                    self.progressCurrent = current
                    self.progressTotal = total
                    self.progressLabel = "Processing lines..."
                }
            }
        default:
            result = TextProcessingService.apply(step, to: currentText)
        }

        text = result
        progressLabel = "Done"
        try? await Task.sleep(for: .milliseconds(400))
        isProcessing = false
    }

    func runScript(_ script: ScriptTemplate) {
        guard !script.steps.isEmpty else { return }
        isProcessing = true
        progressTotal = script.steps.count
        progressCurrent = 0
        progressLabel = "Starting script..."
        pushHistory()
        var result = text
        for (index, step) in script.steps.enumerated() {
            progressCurrent = index + 1
            progressLabel = step.type.displayName
            result = TextProcessingService.apply(step, to: result)
        }
        text = result
        progressLabel = "Done"
        isProcessing = false
    }

    func runScriptOnFilesAndMerge(_ script: ScriptTemplate, urls: [URL]) async {
        guard !script.steps.isEmpty, !urls.isEmpty else { return }
        isProcessing = true
        progressTotal = urls.count
        progressCurrent = 0
        progressLabel = "Starting bulk run..."

        let separator = "-----------------------------------"
        var merged: [String] = []

        for (index, url) in urls.enumerated() {
            let filename = url.lastPathComponent
            progressCurrent = index + 1
            progressLabel = "Processing \(index + 1) of \(urls.count): \(filename)"
            await Task.yield()

            let accessed = url.startAccessingSecurityScopedResource()
            defer { if accessed { url.stopAccessingSecurityScopedResource() } }

            guard let data = try? Data(contentsOf: url),
                  let content = String(data: data, encoding: .utf8) else {
                merged.append("\(filename)\n\(separator)\n(error reading file)")
                continue
            }

            var result = content
            for step in script.steps {
                result = TextProcessingService.apply(step, to: result)
            }
            merged.append("\(filename)\n\(separator)\n\(result)")
        }

        bulkMergeResult = merged.joined(separator: "\n\n")
        progressLabel = "Done"
        try? await Task.sleep(for: .milliseconds(300))
        isProcessing = false
        showBulkMergeExporter = true
    }

    func applyTemplate(_ template: LineRemovalTemplate) {
        let activeStrings = template.strings.filter { !$0.isEmpty }
        guard !activeStrings.isEmpty else { return }
        let lines = text.components(separatedBy: "\n")
        if lines.count > 1000 {
            isProcessing = true
            progressCurrent = 0
            progressTotal = 1
            progressLabel = "Applying template \(template.name)..."
            pushHistory()
            text = TextProcessingService.removeLinesContaining(text, strings: activeStrings)
            progressCurrent = 1
            isProcessing = false
        } else {
            pushHistory()
            text = TextProcessingService.removeLinesContaining(text, strings: activeStrings)
        }
    }

    func undo() {
        guard canUndo else { return }
        historyIndex -= 1
        text = textHistory[historyIndex]
    }

    func redo() {
        guard canRedo else { return }
        historyIndex += 1
        text = textHistory[historyIndex]
    }

    func clearText() {
        pushHistory()
        text = ""
    }

    func loadFileContent(_ result: Result<URL, Error>) {
        guard case .success(let url) = result else { return }
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        guard let data = try? Data(contentsOf: url),
              let content = String(data: data, encoding: .utf8) else { return }
        pushHistory()
        text = content
    }

    func pasteFromClipboard() {
        guard let content = UIPasteboard.general.string else { return }
        pushHistory()
        text = content
    }

    func copyToClipboard() {
        UIPasteboard.general.string = text
    }

    private func pushHistory() {
        if historyIndex < textHistory.count - 1 {
            textHistory = Array(textHistory.prefix(historyIndex + 1))
        }
        textHistory.append(text)
        historyIndex = textHistory.count - 1
        if textHistory.count > 100 {
            textHistory.removeFirst()
            historyIndex -= 1
        }
    }

    func saveScripts() {
        StorageService.shared.saveScripts(scripts)
    }

    func saveTemplates() {
        StorageService.shared.saveTemplates(templates)
    }

    func addScript(_ script: ScriptTemplate) {
        scripts.append(script)
        saveScripts()
    }

    func deleteScript(at offsets: IndexSet) {
        scripts.remove(atOffsets: offsets)
        saveScripts()
    }

    func updateScript(_ script: ScriptTemplate) {
        if let index = scripts.firstIndex(where: { $0.id == script.id }) {
            scripts[index] = script
            saveScripts()
        }
    }

    func addTemplate(_ template: LineRemovalTemplate) {
        templates.append(template)
        saveTemplates()
    }

    func deleteTemplate(at offsets: IndexSet) {
        templates.remove(atOffsets: offsets)
        saveTemplates()
    }

    func updateTemplate(_ template: LineRemovalTemplate) {
        if let index = templates.firstIndex(where: { $0.id == template.id }) {
            templates[index] = template
            saveTemplates()
        }
    }

    func exportScriptsData() -> Data? {
        let export = ScriptExportData(scripts: scripts)
        return try? JSONEncoder().encode(export)
    }

    func exportTemplatesData() -> Data? {
        let export = TemplateExportData(templates: templates)
        return try? JSONEncoder().encode(export)
    }

    func importScripts(from url: URL) -> Int {
        guard url.startAccessingSecurityScopedResource() else { return 0 }
        defer { url.stopAccessingSecurityScopedResource() }
        guard let data = try? Data(contentsOf: url),
              let imported = try? JSONDecoder().decode(ScriptExportData.self, from: data) else { return 0 }
        let newScripts = imported.scripts.map { script in
            ScriptTemplate(name: script.name, steps: script.steps)
        }
        scripts.append(contentsOf: newScripts)
        saveScripts()
        return newScripts.count
    }

    func importTemplates(from url: URL) -> Int {
        guard url.startAccessingSecurityScopedResource() else { return 0 }
        defer { url.stopAccessingSecurityScopedResource() }
        guard let data = try? Data(contentsOf: url),
              let imported = try? JSONDecoder().decode(TemplateExportData.self, from: data) else { return 0 }
        let newTemplates = imported.templates.map { template in
            LineRemovalTemplate(name: template.name, strings: template.strings)
        }
        templates.append(contentsOf: newTemplates)
        saveTemplates()
        return newTemplates.count
    }

    func exportColumnCSV(rows: [[String]], columnIndex: Int, delimiter: String) -> String {
        rows.map { row in
            if columnIndex < row.count {
                return row[columnIndex]
            }
            return ""
        }.joined(separator: "\n")
    }
}
