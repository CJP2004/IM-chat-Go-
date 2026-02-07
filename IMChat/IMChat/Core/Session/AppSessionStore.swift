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

    init(storage: SessionStorage) {
        self.storage = storage
        restoreSession()
    }

    convenience init() {
        self.init(storage: UserDefaultsSessionStorage())
    }

    func restoreSession() {
        guard let stored = storage.loadSession() else {
            clearInMemory()
            return
        }

        token = stored.token
        currentUser = stored.user
        authState = .authenticated
    }

    func saveSession(token: String, user: User) {
        self.token = token
        self.currentUser = user
        self.authState = .authenticated
        storage.saveSession(token: token, user: user)
    }

    func clearSession() {
        storage.clearSession()
        clearInMemory()
    }

    func updateCurrentUser(_ user: User) {
        guard token != nil else { return }
        currentUser = user
        storage.updateUser(user)
    }

    private func clearInMemory() {
        token = nil
        currentUser = nil
        authState = .loggedOut
    }
}
