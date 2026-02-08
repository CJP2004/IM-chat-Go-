/*
FILE-GUIDE: ChatMessage.swift
- 聊天领域模型（UI 最终消费的数据结构）。
- 统一承接 REST 历史消息和 WebSocket 实时消息。
- stableId/dedupFingerprint 用于消息去重和滚动定位。
*/

import Foundation

/// 聊天领域模型（统一 REST 与 WebSocket 消息）
struct ChatMessage: Identifiable, Equatable {
    let stableId: String
    let content: String
    let senderId: Int
    let receiverId: Int
    let type: String
    let mediaUrl: String?
    let createdAt: String?
    let isRead: Bool?
    let serverMessageId: Int?
    let clientMessageId: String?

    var id: String { stableId }

    var dedupFingerprint: String {
        if let clientMessageId {
            return "client-\(clientMessageId)"
        }
        if let serverMessageId {
            return "server-\(serverMessageId)"
        }

        return [
            String(senderId),
            String(receiverId),
            type,
            content,
            mediaUrl ?? "",
        ].joined(separator: "|")
    }
}
