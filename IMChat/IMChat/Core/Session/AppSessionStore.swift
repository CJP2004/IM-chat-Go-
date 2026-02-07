/*
FILE-GUIDE: AppSessionStore.swift
- 全局会话状态中心：保存 authState、currentUser、token。
- 与持久化层（SessionStorage）解耦：内存状态 + 本地存储同步。
- 页面不直接关心持久化细节，只通过 AuthViewModel 读取这里的状态。
*/

import Foundation
import Combine

@MainActor
final class AppSessionStore: ObservableObject {
    enum AuthState {
        case loggedOut
        case authenticated
    }

    @Published private(set) var authState: AuthState = .loggedOut
    @Published private(set) var currentUser: User?
    @Published private(set) var token: String?

    private let storage: SessionStorage

    /// 指定持久化实现创建会话仓库，并在启动时尝试恢复历史登录态。
    init(storage: SessionStorage) {
        self.storage = storage
        restoreSession()
    }

    /// 使用默认 `UserDefaultsSessionStorage` 的便捷初始化入口。
    convenience init() {
        self.init(storage: UserDefaultsSessionStorage())
    }

    /// 从持久化层恢复 token 和用户信息，同步更新鉴权状态。
    func restoreSession() {
        guard let stored = storage.loadSession() else {
            clearInMemory()
            return
        }

        token = stored.token
        currentUser = stored.user
        authState = .authenticated
    }

    /// 保存新会话到内存和持久化层，通常在登录/注册成功后调用。
    func saveSession(token: String, user: User) {
        self.token = token
        self.currentUser = user
        self.authState = .authenticated
        storage.saveSession(token: token, user: user)
    }

    /// 清理当前会话（持久化 + 内存），并把鉴权状态重置为未登录。
    func clearSession() {
        storage.clearSession()
        clearInMemory()
    }

    /// 仅更新当前用户资料（如头像/签名），不改变 token 与登录态。
    func updateCurrentUser(_ user: User) {
        guard token != nil else { return }
        currentUser = user
        storage.updateUser(user)
    }

    /// 统一清空内存中的会话字段，供恢复失败和登出流程复用。
    private func clearInMemory() {
        token = nil
        currentUser = nil
        authState = .loggedOut
    }
}
