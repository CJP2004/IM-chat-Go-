/*
FILE-GUIDE: AuthViewModel.swift
- 认证模块状态与行为中心。
- 职责：登录、注册、登出、恢复会话、连接/断开 WebSocket。
- 它把 sessionStore 状态透传为页面可观察状态。
- 登录成功后的关键动作：保存会话 -> 建立 WS 连接。
*/

import Foundation
import SwiftUI
import Combine

/// 认证视图模型
/// 负责处理登录逻辑和用户状态管理
@MainActor
class AuthViewModel: ObservableObject {
    typealias AuthState = AppSessionStore.AuthState

    @Published var isLoading = false
    @Published var errorMessage: String?

    private let sessionStore: AppSessionStore
    private let authRepository: AuthRepository
    private let webSocketService: WebSocketService
    private var cancellables = Set<AnyCancellable>()

    var authState: AuthState { sessionStore.authState }
    var currentUser: User? { sessionStore.currentUser }
    var token: String? { sessionStore.token }

    init(
        sessionStore: AppSessionStore,
        authRepository: AuthRepository,
        webSocketService: WebSocketService
    ) {
        self.sessionStore = sessionStore
        self.authRepository = authRepository
        self.webSocketService = webSocketService

        // 透传会话状态变更，保持旧的 EnvironmentObject 使用方式不变
        sessionStore.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        restoreSession()
    }
    
    /// 恢复上次登录会话
    func restoreSession() {
        sessionStore.restoreSession()
        if let user = sessionStore.currentUser, let token = sessionStore.token {
            webSocketService.connect(userId: user.id, token: token)
        }
    }
    
    /// 注册方法
    func register(username: String, password: String) async {
        guard !username.isEmpty, !password.isEmpty else {
            self.errorMessage = "Please enter username and password"
            return
        }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let response = try await authRepository.register(username: username, password: password)
            sessionStore.saveSession(token: response.token, user: response.user)
            webSocketService.connect(userId: response.user.id, token: response.token)
            
        } catch {
            // 直接显示错误的本地化描述 (现在 APIError 已经适配了 LocalizedError)
            self.errorMessage = error.localizedDescription
        }
    }

    /// 登录方法
    func login(username: String, password: String) async {
        guard !username.isEmpty, !password.isEmpty else {
            self.errorMessage = "Please enter username and password"
            return
        }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let response = try await authRepository.login(username: username, password: password)
            sessionStore.saveSession(token: response.token, user: response.user)
            // 连接 WebSocket
            webSocketService.connect(userId: response.user.id, token: response.token)
            
        } catch {
            self.errorMessage = "登录失败: \(error.localizedDescription)"
            if let apiError = error as? APIError, case .custom(let msg) = apiError {
                 self.errorMessage = msg
            }
        }
    }
    
    /// 登出
    func logout() {
        webSocketService.disconnect()
        sessionStore.clearSession()
    }

    /// 更新当前用户头像并持久化
    func updateCurrentUserAvatar(url: String) {
        guard let user = currentUser else { return }
        let updatedUser = User(
            id: user.id,
            username: user.username,
            avatar: url,
            tagline: user.tagline,
            lastMessage: user.lastMessage,
            lastMessageTime: user.lastMessageTime
        )
        sessionStore.updateCurrentUser(updatedUser)
    }
}
