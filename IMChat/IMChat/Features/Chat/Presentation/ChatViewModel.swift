/*
FILE-GUIDE: ChatViewModel.swift
- 单聊会话核心逻辑文件。
- 职责包括：
  1) 初始化拉取历史消息
  2) 顶部触发分页加载更早历史
  3) 发送消息的乐观更新
  4) 订阅 WS 并进行回执替换/去重
- 如果聊天体验异常（重复、顺序错乱、回执不替换），优先从这里排查。
*/

import Foundation
import SwiftUI
import Combine

/// 聊天会话视图模型
/// 管理特定会话的消息记录和发送
@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var newMessageText: String = ""
    @Published var isHistoryLoading = false
    @Published var historyErrorMessage: String?
    
    let receiver: User
    private var cancellables = Set<AnyCancellable>()
    private let currentUserId: Int?
    private let chatRepository: ChatRepository
    private let tokenProvider: () -> String?
    private let webSocketService: WebSocketService
    private var pendingOutgoingMessageIds = Set<String>()
    private var nextHistoryPage = 1
    private var hasMoreHistory = true
    private var isLoadingHistoryPage = false

    private let historyPageSize = 30

    private enum HistoryLoadMode {
        case replace
        case prepend
    }
    
    /// 创建会话 VM，初始化订阅并自动触发首屏历史消息加载。
    init(
        receiver: User,
        currentUserId: Int?,
        chatRepository: ChatRepository,
        tokenProvider: @escaping () -> String? = { nil },
        webSocketService: WebSocketService
    ) {
        self.receiver = receiver
        self.currentUserId = currentUserId
        self.chatRepository = chatRepository
        self.tokenProvider = tokenProvider
        self.webSocketService = webSocketService
        
        setupSubscribers()
        Task {
            await fetchHistory()
        }
    }
    
    /// 订阅 WebSocket 消息
    private func setupSubscribers() {
        webSocketService.messageSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.handleIncomingMessage(message)
            }
            .store(in: &cancellables)
    }
    
    /// 处理接收到的消息
    private func handleIncomingMessage(_ message: WSMessageDTO) {
        guard let currentUserId else { return }
        
        let isFromMeToReceiver = (message.senderId == currentUserId && message.receiverId == receiver.id)
        let isFromReceiverToMe = (message.senderId == receiver.id && message.receiverId == currentUserId)
        
        guard isFromMeToReceiver || isFromReceiverToMe else { return }

        // 当后端开始回显 clientMessageId 时，可精确去重乐观消息
        if isFromMeToReceiver,
           let clientMessageId = message.clientMessageId,
           pendingOutgoingMessageIds.contains(clientMessageId) {
            pendingOutgoingMessageIds.remove(clientMessageId)
            let confirmedMessage = message.toDomain()
            if let index = messages.firstIndex(where: {
                $0.clientMessageId == clientMessageId || $0.stableId == "local-\(clientMessageId)"
            }) {
                messages[index] = confirmedMessage
            } else {
                messages.append(confirmedMessage)
            }
            return
        }

        let incoming = message.toDomain()
        if messages.contains(where: { $0.stableId == incoming.stableId }) {
            return
        }
        self.messages.append(incoming)
    }
    
    /// 获取历史消息
    func fetchHistory() async {
        guard let currentUserId else { return }
        guard let token = tokenProvider(), !token.isEmpty else {
            historyErrorMessage = "Session expired. Please log in again."
            return
        }
        historyErrorMessage = nil
        hasMoreHistory = true
        nextHistoryPage = 1
        messages = []
        await loadHistoryPage(currentUserId: currentUserId, token: token, page: nextHistoryPage, mode: .replace)
    }

    /// 当顶部消息出现时按需加载更早历史，避免重复并发请求。
    func loadMoreHistoryIfNeeded(currentMessage: ChatMessage) {
        guard let currentUserId else { return }
        guard let token = tokenProvider(), !token.isEmpty else { return }
        guard hasMoreHistory, !isLoadingHistoryPage else { return }
        guard messages.first?.stableId == currentMessage.stableId else { return }

        Task {
            await loadHistoryPage(currentUserId: currentUserId, token: token, page: nextHistoryPage, mode: .prepend)
        }
    }

    /// 历史分页失败时的重试入口：有首条消息则继续翻页，无消息则重拉首屏。
    func retryLoadMoreHistory() {
        guard let firstMessage = messages.first else {
            Task { await fetchHistory() }
            return
        }
        loadMoreHistoryIfNeeded(currentMessage: firstMessage)
    }
    
    /// 发送消息
    func sendMessage() {
        guard !newMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard let currentUserId else { return }
        
        let content = newMessageText
        newMessageText = "" // 清空输入框

        let clientMessageId = UUID().uuidString
        
        let wsMessage = WSMessageDTO(
            senderId: currentUserId,
            receiverId: receiver.id,
            content: content,
            type: "text",
            mediaUrl: "",
            clientMessageId: clientMessageId
        )

        let optimisticMessage = ChatMessage(
            stableId: "local-\(clientMessageId)",
            content: content,
            senderId: currentUserId,
            receiverId: receiver.id,
            type: "text",
            mediaUrl: nil,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            isRead: false,
            serverMessageId: nil,
            clientMessageId: clientMessageId
        )

        pendingOutgoingMessageIds.insert(clientMessageId)
        messages.append(optimisticMessage)
        webSocketService.sendMessage(wsMessage)
    }

    /// 通用历史分页加载器：根据模式执行替换或头插，并维护分页游标状态。
    private func loadHistoryPage(currentUserId: Int, token: String, page: Int, mode: HistoryLoadMode) async {
        guard !isLoadingHistoryPage else { return }

        isLoadingHistoryPage = true
        isHistoryLoading = true
        defer {
            isLoadingHistoryPage = false
            isHistoryLoading = false
        }

        do {
            let batch = try await chatRepository.fetchHistory(
                currentUserId: currentUserId,
                receiverId: receiver.id,
                page: page,
                pageSize: historyPageSize,
                token: token
            )

            historyErrorMessage = nil

            switch mode {
            case .replace:
                messages = batch
                if batch.count < historyPageSize {
                    hasMoreHistory = false
                } else {
                    hasMoreHistory = true
                    nextHistoryPage = page + 1
                }
            case .prepend:
                let existingIds = Set(messages.map(\.stableId))
                let olderMessages = batch.filter { !existingIds.contains($0.stableId) }

                // 后端不支持分页时可能返回同一批数据；此时直接停止继续翻页。
                guard !olderMessages.isEmpty else {
                    hasMoreHistory = false
                    return
                }

                messages.insert(contentsOf: olderMessages, at: 0)

                if batch.count < historyPageSize {
                    hasMoreHistory = false
                } else {
                    nextHistoryPage = page + 1
                }
            }
        } catch {
            historyErrorMessage = "Failed to load messages. Please try again."
        }
    }
}
