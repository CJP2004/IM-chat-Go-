/*
FILE-GUIDE: RESTMessageDTO.swift
- 历史消息接口 DTO（后端字段 -> 前端可用模型）。
- 通过 CodingKeys 适配后端大写字段名。
- toDomain() 把 DTO 转换成 ChatMessage，避免 UI 直接依赖接口结构。
*/

import Foundation

/// 历史消息接口 DTO（/api/messages）
struct RESTMessageDTO: Decodable {
    let id: Int?
    let content: String
    let senderId: Int
    let receiverId: Int
    let type: String
    let mediaUrl: String?
    let createdAt: String?
    let isRead: Bool?

    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case content = "Content"
        case senderId = "SenderID"
        case receiverId = "ReceiverID"
        case type = "Type"
        case mediaUrl = "MediaURL"
        case createdAt = "CreatedAt"
        case isRead = "IsRead"
    }
}

extension RESTMessageDTO {
    /// 把历史消息 DTO 转换为统一领域模型，并构造可稳定去重的 `stableId`。
    func toDomain() -> ChatMessage {
        let stableId: String
        if let id {
            stableId = "server-\(id)"
        } else {
            let fallback = [
                String(senderId),
                String(receiverId),
                type,
                content,
                mediaUrl ?? "",
                createdAt ?? "",
            ].joined(separator: "|")
            stableId = "history-\(fallback)"
        }

        return ChatMessage(
            stableId: stableId,
            content: content,
            senderId: senderId,
            receiverId: receiverId,
            type: type,
            mediaUrl: mediaUrl,
            createdAt: createdAt,
            isRead: isRead,
            serverMessageId: id,
            clientMessageId: nil
        )
    }
}
