import Foundation
import SwiftUI
import Combine

/// 聊天列表视图模型
/// 负责获取联系人列表
@MainActor
class ChatListViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var isLoading = false
    
    /// 获取用户列表
    func fetchUsers() async {
        isLoading = true
        do {
            // 假设获取所有用户，或者获取有聊天记录的用户
            // 根据 stores/chat.ts -> /users?userId=...
            // 我们需要传递当前用户的 ID
            // 这里我们从 UserDefaults 或 AuthViewModel 获取当前用户 ID 比较麻烦
            // 更好的方式是让 ChatListViewModel 依赖 AuthViewModel，或者在 View 层传递 ID
            
            // 这里我们假设 fetchUsers 接口需要 userId 参数
            guard let userData = UserDefaults.standard.data(forKey: "auth_user_json"),
                  let currentUser = try? JSONDecoder().decode(User.self, from: userData) else {
                return
            }
            
            // 构造参数
            // 注意：APIService 的 request 方法目前是基础的，可能需要调整支持 query parameters
            // 这里简化处理，直接拼接到 endpoint，或者修改 APIService
            // 让我们简单点，直接修改 endpoint 字符串
            let endpoint = "/api/users?userId=\(currentUser.id)"
            
            let response: [User] = try await APIService.shared.request(endpoint: endpoint)
            self.users = response
            
        } catch {
            print("Failed to fetch users: \(error)")
        }
        isLoading = false
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
