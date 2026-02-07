/*
FILE-GUIDE: ContentView.swift
- 根路由视图：根据 authState 在登录页和主 Tab 页之间切换。
- 这里不发网络请求，不维护复杂状态，职责是“路由决策”。
- 读代码顺序：先看 authState 来源（AuthViewModel），再看切换到哪个页面。
*/

import SwiftUI

/// 根视图
/// 根据登录状态切换显示 LoginView 或 ChatListView (主页)
struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        Group {
            switch authViewModel.authState {
            case .loggedOut:
                LoginView()
            case .authenticated:
                 MainTabView()
            }
        }
    }
}
