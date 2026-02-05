import Foundation
import SwiftUI
import Combine

/// 聊天会话视图模型
/// 管理特定会话的消息记录和发送
@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var newMessageText: String = ""
    
    let receiver: User
    private var cancellables = Set<AnyCancellable>()
    private var currentUser: User?
    
    init(receiver: User) {
        self.receiver = receiver
        
        // 加载当前用户
        if let userData = UserDefaults.standard.data(forKey: "auth_user_json"),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            self.currentUser = user
        }
        
        setupSubscribers()
        fetchHistory()
    }
    
    /// 订阅 WebSocket 消息
    private func setupSubscribers() {
        WebSocketService.shared.messageSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.handleIncomingMessage(message)
            }
            .store(in: &cancellables)
    }
    
    /// 处理接收到的消息
    private func handleIncomingMessage(_ message: Message) {
        guard let currentUserId = currentUser?.id else { return }
        
        // 逻辑：
        // 1. 如果消息是我发给对方的 (多端同步)
        // 2. 如果消息是对方发给我的
        let isFromMeToReceiver = (message.senderId == currentUserId && message.receiverId == receiver.id)
        let isFromReceiverToMe = (message.senderId == receiver.id && message.receiverId == currentUserId)
        
        if isFromMeToReceiver || isFromReceiverToMe {
            // 避免重复添加 (如果有 ID 的话)
            // 这里简单直接 append
            self.messages.append(message)
        }
    }
    
    /// 获取历史消息
    func fetchHistory() {
        guard let currentUserId = currentUser?.id else { return }
        
        Task {
            do {
                // Endpoint: /messages?senderId=...&receiverId=...
                let endpoint = "/api/messages?senderId=\(currentUserId)&receiverId=\(receiver.id)"
                let response: [Message] = try await APIService.shared.request(endpoint: endpoint)
                
                self.messages = response
            } catch {
                print("Failed to fetch history: \(error)")
            }
        }
    }
    
    /// 发送消息
    func sendMessage() {
        guard !newMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard let currentUserId = currentUser?.id else { return }
        
        let content = newMessageText
        newMessageText = "" // 清空输入框
        
        // 构造消息对象
        let msg = Message(
            content: content,
            senderId: currentUserId,
            receiverId: receiver.id,
            type: "text",
            mediaUrl: "",
            createdAt: ISO8601DateFormatter().string(from: Date()), // 简单模拟时间格式
            isRead: false
        )
        
        // 1. 通过 WebSocket 发送
        WebSocketService.shared.sendMessage(msg)
        
        // 2. 乐观更新 UI (直接添加到列表)
        self.messages.append(msg)
    }
}
