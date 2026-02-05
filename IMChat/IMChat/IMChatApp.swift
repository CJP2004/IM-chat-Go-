import SwiftUI

/// 应用入口文件
@main
struct IMChatApp: App {
    // 创建全局唯一的 AuthViewModel
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
        }
    }
}
