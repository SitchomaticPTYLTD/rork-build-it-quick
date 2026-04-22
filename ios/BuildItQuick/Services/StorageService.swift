import Foundation

nonisolated final class StorageService: Sendable {
    static let shared = StorageService()

    private let scriptsKey = "saved_scripts"
    private let templatesKey = "saved_templates"

    func loadScripts() -> [ScriptTemplate] {
        guard let data = UserDefaults.standard.data(forKey: scriptsKey) else { return [] }
        return (try? JSONDecoder().decode([ScriptTemplate].self, from: data)) ?? []
    }

    func saveScripts(_ scripts: [ScriptTemplate]) {
        guard let data = try? JSONEncoder().encode(scripts) else { return }
        UserDefaults.standard.set(data, forKey: scriptsKey)
    }

    func loadTemplates() -> [LineRemovalTemplate] {
        guard let data = UserDefaults.standard.data(forKey: templatesKey) else { return [] }
        return (try? JSONDecoder().decode([LineRemovalTemplate].self, from: data)) ?? []
    }

    func saveTemplates(_ templates: [LineRemovalTemplate]) {
        guard let data = try? JSONEncoder().encode(templates) else { return }
        UserDefaults.standard.set(data, forKey: templatesKey)
    }
}
