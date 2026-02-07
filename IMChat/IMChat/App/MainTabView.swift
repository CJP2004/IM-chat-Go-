/*
FILE-GUIDE: MainTabView.swift
- 主壳页面：管理三个 Tab（消息、群组、设置）。
- 这里还统一配置了 UITabBar 外观（颜色、透明背景、图标状态）。
- 页面通过容器注入 ViewModel，避免在视图里直接 new 业务对象。
- 如果某个 Tab 页面拿不到数据，先检查 container 注入是否完整。
*/

import SwiftUI

enum Tab {
    case message
    case group
    case setting
}

/// 主 Tab 视图
struct MainTabView: View {
    @EnvironmentObject private var container: AppContainer
    @State private var selectedTab: Tab = .message
    
    init() {
            // 1. 初始化外观配置
            let appearance = UITabBarAppearance()
            
            // 【关键步骤 1】重置为透明背景
            appearance.configureWithTransparentBackground()
            
            // 【关键步骤 2】一定要把这个背景特效设为 nil
            //
            appearance.backgroundEffect = nil
            
            // 【关键步骤 3】去掉阴影分割线
            appearance.shadowColor = .clear
            appearance.shadowImage = UIImage()
            
            // 4. 设置字体和图标颜色 (保持之前的黑金配色不变)
            let uiGoldColor = UIColor.theme.gold
            let uiGrayColor = UIColor.systemGray
            
            let itemAppearance = UITabBarItemAppearance()
            
            // 未选中状态
            itemAppearance.normal.iconColor = uiGrayColor
            itemAppearance.normal.titleTextAttributes = [.foregroundColor: uiGrayColor]
            
            // 选中状态
            itemAppearance.selected.iconColor = uiGoldColor
            itemAppearance.selected.titleTextAttributes = [.foregroundColor: uiGoldColor]
            
            appearance.stackedLayoutAppearance = itemAppearance
            appearance.inlineLayoutAppearance = itemAppearance
            appearance.compactInlineLayoutAppearance = itemAppearance
            
            // 5. 应用到全局
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 1. 消息页面
            NavigationStack {
                ChatListView(
                    viewModel: container.chatListViewModel,
                    makeChatViewModel: { receiver, currentUserId in
                        container.makeChatViewModel(receiver: receiver, currentUserId: currentUserId)
                    }
                )
            }
            .tabItem {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                Text("Message")
            }
            .tag(Tab.message)
            
            // 2. 群组页面
            NavigationStack {
                GroupListView()
            }
            .tabItem {
                Image(systemName: "person.3.fill")
                Text("Group")
            }
            .tag(Tab.group)
            
            // 3. 设置页面
            NavigationStack {
                ProfileView(viewModel: container.profileViewModel)
            }
            .tabItem {
                Image(systemName: "gearshape.fill")
                Text("Setting")
            }
            .tag(Tab.setting)
        }
        .ignoresSafeArea(.keyboard) // 键盘弹出时 TabBar 不会上移
        .preferredColorScheme(.dark) // 强制深色模式
        .accentColor(Color.theme.gold) // 再次确保 SwiftUI 层面的选中色也是金色
    }
}

#Preview {
    let container = AppContainer(
        apiClient: APIClient(),
        webSocketService: WebSocketService.shared,
        sessionStorage: InMemorySessionStorage()
    )

    MainTabView()
        .environmentObject(container)
        .environmentObject(container.authViewModel)
        .environmentObject(container.sessionStore)
}
