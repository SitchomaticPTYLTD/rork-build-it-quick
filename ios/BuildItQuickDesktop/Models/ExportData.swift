import SwiftUI
import UniformTypeIdentifiers

nonisolated struct ScriptExportData: Codable, Sendable {
    let version: Int
    let type: String
    let scripts: [ScriptTemplate]

    init(scripts: [ScriptTemplate]) {
        self.version = 1
        self.type = "scripts"
        self.scripts = scripts
    }
}

nonisolated struct TemplateExportData: Codable, Sendable {
    let version: Int
    let type: String
    let templates: [LineRemovalTemplate]

    init(templates: [LineRemovalTemplate]) {
        self.version = 1
        self.type = "templates"
        self.templates = templates
    }
}

nonisolated struct ExportFile: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        guard let fileData = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        data = fileData
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
