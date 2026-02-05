import Foundation

/// 消息模型
/// 用于解析 WebSocket 消息和历史记录 API 响应
struct Message: Codable, Identifiable, Equatable {
    // 使用 UUID 生成唯一 ID，因为 SwiftUI List 需要 Identifiable
    // 如果后端没有返回唯一的消息 ID，我们在本地生成一个
    var id: String = UUID().uuidString
    
    let content: String
    let senderId: Int
    let receiverId: Int
    let type: String // "text", "image", "read_ack"
    let mediaUrl: String?
    let createdAt: String // Go 后端的时间字符串
    var isRead: Bool?
    
    // 映射 JSON 键名
    // 根据前端 stores/chat.ts，后端返回的字段是 PascalCase (大驼峰)
    enum CodingKeys: String, CodingKey {
        case content = "Content"
        case senderId = "SenderID"
        case receiverId = "ReceiverID"
        case type = "Type"
        case mediaUrl = "MediaURL"
        case createdAt = "CreatedAt"
        case isRead = "IsRead"
    }
}
