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
    /// 从持久化层读取完整会话（token + user）；无会话返回 nil。
    func loadSession() -> StoredSession?
    /// 持久化写入完整会话，通常在登录成功后调用。
    func saveSession(token: String, user: User)
    /// 仅更新已登录用户资料，不改动 token。
    func updateUser(_ user: User)
    /// 清除所有会话相关持久化数据。
    func clearSession()
}

protocol SecureTokenStorage {
    /// 从安全存储读取 token。
    func loadToken() -> String?
    /// 把 token 写入安全存储（如 Keychain）。
    func saveToken(_ token: String)
    /// 从安全存储移除 token。
    func clearToken()
}

final class KeychainTokenStorage: SecureTokenStorage {
    private let service: String
    private let account: String

    /// 配置 Keychain 条目标识（service/account）。
    init(
        service: String = Bundle.main.bundleIdentifier ?? "com.CyrusChu.IMChat",
        account: String = "auth_token"
    ) {
        self.service = service
        self.account = account
    }

    /// 从 Keychain 读取 token，并做 Data -> String 解码。
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

    /// 先删旧值再写新值，确保账号下只有一条最新 token。
    func saveToken(_ token: String) {
        clearToken()

        guard let data = token.data(using: .utf8) else { return }
        var query = baseQuery
        query[kSecValueData as String] = data
        SecItemAdd(query as CFDictionary, nil)
    }

    /// 删除当前 service/account 对应的 Keychain token。
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

    /// 配置 UserDefaults 键名及底层 token 安全存储实现。
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

    /// 从 token 存储和 UserDefaults 组合还原完整会话。
    func loadSession() -> StoredSession? {
        guard let token = loadToken(),
              let userData = userDefaults.data(forKey: userKey),
              let user = try? JSONDecoder().decode(User.self, from: userData) else {
            return nil
        }
        return StoredSession(token: token, user: user)
    }

    /// 将 token 写入安全存储，将用户模型写入 UserDefaults。
    func saveSession(token: String, user: User) {
        tokenStorage.saveToken(token)
        userDefaults.removeObject(forKey: tokenKey)
        if let userData = try? JSONEncoder().encode(user) {
            userDefaults.set(userData, forKey: userKey)
        }
    }

    /// 更新当前用户模型的缓存副本。
    func updateUser(_ user: User) {
        guard let userData = try? JSONEncoder().encode(user) else { return }
        userDefaults.set(userData, forKey: userKey)
    }

    /// 清理 token 与用户缓存，彻底退出登录态。
    func clearSession() {
        tokenStorage.clearToken()
        userDefaults.removeObject(forKey: tokenKey)
        userDefaults.removeObject(forKey: userKey)
    }

    /// 优先从 Keychain 读 token；若发现旧版 token 在 UserDefaults，则自动迁移。
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

    /// 从内存返回当前会话，常用于预览或测试。
    func loadSession() -> StoredSession? {
        storedSession
    }

    /// 在内存中保存会话，不落盘。
    func saveSession(token: String, user: User) {
        storedSession = StoredSession(token: token, user: user)
    }

    /// 仅替换内存中的用户对象，保持 token 不变。
    func updateUser(_ user: User) {
        guard let token = storedSession?.token else { return }
        storedSession = StoredSession(token: token, user: user)
    }

    /// 清空内存会话。
    func clearSession() {
        storedSession = nil
    }
}
