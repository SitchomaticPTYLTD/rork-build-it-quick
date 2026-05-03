import Foundation
import Security

nonisolated final class AIKeychainStore: Sendable {
    static let shared = AIKeychainStore()

    private let service = "app.rork.build-it-quick-j9nou2c.ai-text-morph"

    private init() {}

    func read(_ account: String) -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return ""
        }
        return value
    }

    func save(_ value: String, account: String) {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        if trimmedValue.isEmpty {
            SecItemDelete(query as CFDictionary)
            return
        }

        let data = Data(trimmedValue.utf8)
        let attributes: [String: Any] = [kSecValueData as String: data]
        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        guard updateStatus == errSecItemNotFound else { return }

        var createQuery = query
        createQuery[kSecValueData as String] = data
        createQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(createQuery as CFDictionary, nil)
    }
}
