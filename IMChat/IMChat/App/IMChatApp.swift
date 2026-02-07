/*
FILE-GUIDE: IMChatApp.swift
- 这是应用入口，负责创建并注入全局依赖。
- 你可以把它理解成“启动装配层”，只做对象初始化，不做业务逻辑。
- 关键对象：AppContainer（依赖容器）、AuthViewModel（登录状态）、AppSessionStore（会话状态）。
- 调试建议：如果页面切换不对，先看这里是否正确注入 environmentObject。
*/

import SwiftUI

/// 应用入口文件
@main
struct IMChatApp: App {
    @StateObject private var container: AppContainer
    // 创建全局唯一的 AuthViewModel
    @StateObject private var authViewModel: AuthViewModel

    init() {
        let container = AppContainer()
        _container = StateObject(wrappedValue: container)
        _authViewModel = StateObject(wrappedValue: container.authViewModel)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(container)
                .environmentObject(authViewModel)
                .environmentObject(container.sessionStore)
        }
    }
}
