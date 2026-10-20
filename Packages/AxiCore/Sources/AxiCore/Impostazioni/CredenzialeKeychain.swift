import Foundation
import Security

/// One generic password in the user's Keychain. Its value is never logged.
public struct CredenzialeKeychain: Sendable {
    public enum Errore: Error, Equatable {
        case keychain(OSStatus)
    }

    public let service: String
    public let account: String

    public init(service: String, account: String) {
        self.service = service
        self.account = account
    }

    private var query: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }

    /// The stored value, or `nil` when none is stored.
    public func leggi() throws -> String? {
        var query = self.query
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess, let data = result as? Data else {
            throw Errore.keychain(status)
        }
        return String(decoding: data, as: UTF8.self)
    }

    /// Stores the value, replacing the previous one. An empty value removes it.
    public func scrivi(_ valore: String) throws {
        guard !valore.isEmpty else {
            try cancella()
            return
        }
        let data = Data(valore.utf8)
        let status = SecItemUpdate(
            query as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        if status == errSecSuccess {
            return
        }
        guard status == errSecItemNotFound else {
            throw Errore.keychain(status)
        }
        var add = query
        add[kSecValueData as String] = data
        let addStatus = SecItemAdd(add as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw Errore.keychain(addStatus)
        }
    }

    /// Removes the stored value, if any.
    public func cancella() throws {
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw Errore.keychain(status)
        }
    }
}
