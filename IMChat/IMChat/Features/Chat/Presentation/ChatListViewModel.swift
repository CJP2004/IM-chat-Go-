/*
FILE-GUIDE: ChatListViewModel.swift
- 联系人列表页面的状态管理。
- 职责：拉取用户列表、管理 loading/error 状态。
- tokenProvider 用于按需读取当前 token，避免 ViewModel 持有会话对象本身。
*/

import Foundation
import SwiftUI
import Combine

/// 聊天列表视图模型
/// 负责获取联系人列表
@MainActor
class ChatListViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let chatRepository: ChatRepository
    private let tokenProvider: () -> String?

    /// 注入列表所需依赖；token 通过闭包惰性获取，避免强耦合会话对象。
    init(
        chatRepository: ChatRepository,
        tokenProvider: @escaping () -> String? = { nil }
    ) {
        self.chatRepository = chatRepository
        self.tokenProvider = tokenProvider
    }
    
    /// 获取用户列表
    func fetchUsers(currentUserId: Int?) async {
        guard let currentUserId = currentUserId else {
            users = []
            errorMessage = nil
            return
        }
        guard let token = tokenProvider(), !token.isEmpty else {
            users = []
            errorMessage = "Session expired. Please log in again."
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await chatRepository.fetchUsers(currentUserId: currentUserId, token: token)
            self.users = response
        } catch {
            errorMessage = "Failed to load contacts. Please try again."
        }
    }
    
    /// 加载模拟数据 (用于预览)
    func loadMockData() {
            self.users = [
                User(id: 1, username: "Elon Musk", avatar: "https://i.pravatar.cc/150?u=1", tagline: "To Mars! 🚀", lastMessage: "Are we going to Mars?", lastMessageTime: "14:30"),
                User(id: 2, username: "Tim Cook", avatar: "https://i.pravatar.cc/150?u=2", tagline: "Good morning!", lastMessage: "New iPhone is coming.", lastMessageTime: "Yesterday"),
                User(id: 3, username: "Taylor Swift", avatar: "https://i.pravatar.cc/150?u=3", tagline: "1989 (Taylor's Version)", lastMessage: "Singing...", lastMessageTime: "12:00"),
                User(id: 4, username: "Gopher", avatar: "https://i.pravatar.cc/150?u=4", tagline: "I love Go language", lastMessage: nil, lastMessageTime: nil)
            ]
        }
}
