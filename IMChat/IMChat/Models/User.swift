import Foundation

/// 用户模型
/// 对应后端返回的用户数据结构
struct User: Codable, Identifiable {
    let id: Int
    let username: String
    let avatar: String
    let tagline: String?
    let lastMessage: String?
    let lastMessageTime: String?
    
    // 如果后端的 JSON 键名与属性名不完全一致，可以在这里定义映射
    // 根据前端 stores/chat.ts 来看，User 对象的字段似乎是小写的 (res.data -> User[])
    // 如果后端返回的是大写，我们需要调整 CodingKeys
    // 假设 /login 接口返回的 user 对象字段为标准的 JSON 风格 (username, avatar 等)
}

/// 登录响应结构
struct LoginResponse: Codable {
    let token: String
    let user: User
}
