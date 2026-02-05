import Foundation
import SwiftUI
import Combine

/// 认证视图模型
/// 负责处理登录逻辑和用户状态管理
@MainActor
class AuthViewModel: ObservableObject {
    // 登录成功后，currentState 变为 .authenticated
    enum AuthState {
        case loggedOut
        case authenticated
    }
    
    @Published var authState: AuthState = .loggedOut
    @Published var currentUser: User?
    @Published var token: String?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let tokenKey = "auth_token"
    private let userKey = "auth_user_json" // 简单起见，我们将用户 JSON 存入 UserDefaults
    
    init() {
        // 尝试恢复会话
        restoreSession()
    }
    
    /// 恢复上次登录会话
    func restoreSession() {
        if let savedToken = UserDefaults.standard.string(forKey: tokenKey),
           let savedUserData = UserDefaults.standard.data(forKey: userKey),
           let savedUser = try? JSONDecoder().decode(User.self, from: savedUserData) {
            
            self.token = savedToken
            self.currentUser = savedUser
            self.authState = .authenticated
            
            // 连接 WebSocket
            WebSocketService.shared.connect(userId: savedUser.id)
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
        
        do {
            let response: LoginResponse = try await APIService.shared.request(
                endpoint: "/api/register",
                method: .POST,
                body: ["username": username, "password": password]
            )
            
            self.token = response.token
            self.currentUser = response.user
            self.authState = .authenticated
            
            UserDefaults.standard.set(response.token, forKey: tokenKey)
            if let userData = try? JSONEncoder().encode(response.user) {
                UserDefaults.standard.set(userData, forKey: userKey)
            }
            
            WebSocketService.shared.connect(userId: response.user.id)
            
        } catch {
            // 直接显示错误的本地化描述 (现在 APIError 已经适配了 LocalizedError)
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }

    /// 登录方法
    func login(username: String, password: String) async {
        guard !username.isEmpty, !password.isEmpty else {
            self.errorMessage = "Please enter username and password"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // 调用 API
            // 假设后端返回结构是 { "token": "...", "user": {...} }
            // 注意：需要根据实际后端响应调整 LoginResponse
            let response: LoginResponse = try await APIService.shared.request(
                endpoint: "/api/login",
                method: .POST,
                body: ["username": username, "password": password]
            )
            
            self.token = response.token
            self.currentUser = response.user
            self.authState = .authenticated
            
            // 持久化 Token 和 User
            UserDefaults.standard.set(response.token, forKey: tokenKey)
            if let userData = try? JSONEncoder().encode(response.user) {
                UserDefaults.standard.set(userData, forKey: userKey)
            }
            
            // 连接 WebSocket
            WebSocketService.shared.connect(userId: response.user.id)
            
        } catch {
            self.errorMessage = "登录失败: \(error.localizedDescription)"
            if let apiError = error as? APIError, case .custom(let msg) = apiError {
                 self.errorMessage = msg
            }
        }
        
        isLoading = false
    }
    
    /// 登出
    func logout() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: userKey)
        
        WebSocketService.shared.disconnect()
        
        self.token = nil
        self.currentUser = nil
        self.authState = .loggedOut
    }
}
