/*
FILE-GUIDE: WSMessageDTO.swift
- WebSocket 消息 DTO。
- 兼容新老协议字段（messageId 与 legacy ID）。
- clientMessageId 用于乐观消息确认，messageId 用于服务端落库回执。
- toDomain() 负责把实时包统一转为 ChatMessage。
*/

import Foundation

/// WebSocket 消息 DTO（实时收发）
struct WSMessageDTO: Codable, Equatable {
    let senderId: Int
    let receiverId: Int
    let content: String
    let type: String
    let mediaUrl: String
    let clientMessageId: String?
    let messageId: Int?

    enum CodingKeys: String, CodingKey {
        case senderId
        case receiverId
        case content
        case type
        case mediaUrl
        case clientMessageId
        case messageId
    }

    enum LegacyCodingKeys: String, CodingKey {
        case id = "ID"
    }

    /// 创建一条待发送或已接收的 WS 消息模型。
    init(
        senderId: Int,
        receiverId: Int,
        content: String,
        type: String,
        mediaUrl: String = "",
        clientMessageId: String? = nil,
        messageId: Int? = nil
    ) {
        self.senderId = senderId
        self.receiverId = receiverId
        self.content = content
        self.type = type
        self.mediaUrl = mediaUrl
        self.clientMessageId = clientMessageId
        self.messageId = messageId
    }

    /// 自定义解码：优先读新字段 `messageId`，兼容旧字段 `ID`。
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        senderId = try container.decode(Int.self, forKey: .senderId)
        receiverId = try container.decode(Int.self, forKey: .receiverId)
        content = try container.decodeIfPresent(String.self, forKey: .content) ?? ""
        type = try container.decodeIfPresent(String.self, forKey: .type) ?? "text"
        mediaUrl = try container.decodeIfPresent(String.self, forKey: .mediaUrl) ?? ""
        clientMessageId = try container.decodeIfPresent(String.self, forKey: .clientMessageId)
        if let messageId = try container.decodeIfPresent(Int.self, forKey: .messageId) {
            self.messageId = messageId
        } else {
            let legacyContainer = try decoder.container(keyedBy: LegacyCodingKeys.self)
            self.messageId = try legacyContainer.decodeIfPresent(Int.self, forKey: .id)
        }
    }

    var dedupFingerprint: String {
        if let clientMessageId {
            return "client-\(clientMessageId)"
        }
        if let messageId {
            return "server-\(messageId)"
        }

        return [
            String(senderId),
            String(receiverId),
            type,
            content,
            mediaUrl,
        ].joined(separator: "|")
    }

    /// 把 WS DTO 统一映射到聊天领域模型，生成可用于 UI 去重和渲染的稳定 ID。
    func toDomain(stableId: String? = nil, createdAt: String? = nil) -> ChatMessage {
        let resolvedStableId: String
        if let stableId {
            resolvedStableId = stableId
        } else if let messageId {
            resolvedStableId = "server-\(messageId)"
        } else if let clientMessageId {
            resolvedStableId = "client-\(clientMessageId)"
        } else {
            resolvedStableId = "ws-\(UUID().uuidString)"
        }

        return ChatMessage(
            stableId: resolvedStableId,
            content: content,
            senderId: senderId,
            receiverId: receiverId,
            type: type,
            mediaUrl: mediaUrl.isEmpty ? nil : mediaUrl,
            createdAt: createdAt,
            isRead: nil,
            serverMessageId: messageId,
            clientMessageId: clientMessageId
        )
    }
}
