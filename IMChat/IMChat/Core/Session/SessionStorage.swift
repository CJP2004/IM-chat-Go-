/*
FILE-GUIDE: SessionStorage.swift
- 会话持久化抽象与实现。
- 协议：SessionStorage / SecureTokenStorage。
- 默认实现：token 存 Keychain，用户信息存 UserDefaults。
- 还提供 InMemorySessionStorage 便于 Preview/测试。
- 迁移逻辑：兼容旧版本 token 在 UserDefaults 的场景。
*/

import Foundation
import Security

struct StoredSession {
    let token: String
    let user: User
}

protocol SessionStorage {
    func loadSession() -> StoredSession?
    func saveSession(token: String, user: User)
    func updateUser(_ user: User)
    func clearSession()
}

protocol SecureTokenStorage {
    func loadToken() -> String?
    func saveToken(_ token: String)
    func clearToken()
}

final class KeychainTokenStorage: SecureTokenStorage {
    private let service: String
    private let account: String

    init(
        service: String = Bundle.main.bundleIdentifier ?? "com.CyrusChu.IMChat",
        account: String = "auth_token"
    ) {
        self.service = service
        self.account = account
    }

    func loadToken() -> String? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }
        return token
    }

    func saveToken(_ token: String) {
        clearToken()

        guard let data = token.data(using: .utf8) else { return }
        var query = baseQuery
        query[kSecValueData as String] = data
        SecItemAdd(query as CFDictionary, nil)
    }

    func clearToken() {
        SecItemDelete(baseQuery as CFDictionary)
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }
}

final class UserDefaultsSessionStorage: SessionStorage {
    private let userDefaults: UserDefaults
    private let tokenStorage: SecureTokenStorage
    private let tokenKey: String
    private let userKey: String

    init(
        userDefaults: UserDefaults = .standard,
        tokenStorage: SecureTokenStorage = KeychainTokenStorage(),
        tokenKey: String = "auth_token",
        userKey: String = "auth_user_json"
    ) {
        self.userDefaults = userDefaults
        self.tokenStorage = tokenStorage
        self.tokenKey = tokenKey
        self.userKey = userKey
    }

    func loadSession() -> StoredSession? {
        guard let token = loadToken(),
              let userData = userDefaults.data(forKey: userKey),
              let user = try? JSONDecoder().decode(User.self, from: userData) else {
            return nil
        }
        return StoredSession(token: token, user: user)
    }

    func saveSession(token: String, user: User) {
        tokenStorage.saveToken(token)
        userDefaults.removeObject(forKey: tokenKey)
        if let userData = try? JSONEncoder().encode(user) {
            userDefaults.set(userData, forKey: userKey)
        }
    }

    func updateUser(_ user: User) {
        guard let userData = try? JSONEncoder().encode(user) else { return }
        userDefaults.set(userData, forKey: userKey)
    }

    func clearSession() {
        tokenStorage.clearToken()
        userDefaults.removeObject(forKey: tokenKey)
        userDefaults.removeObject(forKey: userKey)
    }

    private func loadToken() -> String? {
        if let token = tokenStorage.loadToken() {
            return token
        }

        // 兼容旧版本：若 token 仍在 UserDefaults，自动迁移到 Keychain。
        if let legacyToken = userDefaults.string(forKey: tokenKey) {
            tokenStorage.saveToken(legacyToken)
            userDefaults.removeObject(forKey: tokenKey)
            return legacyToken
        }

        return nil
    }
}

final class InMemorySessionStorage: SessionStorage {
    private var storedSession: StoredSession?

    func loadSession() -> StoredSession? {
        storedSession
    }

    func saveSession(token: String, user: User) {
        storedSession = StoredSession(token: token, user: user)
    }

    func updateUser(_ user: User) {
        guard let token = storedSession?.token else { return }
        storedSession = StoredSession(token: token, user: user)
    }

    func clearSession() {
        storedSession = nil
    }
}
