import SwiftUI

enum Tab {
    case message
    case group
}

/// 主 Tab 视图
/// 使用原生 TabView 并配合 UITabBarAppearance 实现液态玻璃效果
struct MainTabView: View {
    @State private var selectedTab: Tab = .message
    
    init() {
        Self.configureAppearance()
    }
    
    /// 配置 TabBar 全局外观 (Liquid Glass)
    static func configureAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground() // 基础设为透明，以便叠加模糊
        
        // 1. 背景效果 (Liquid Glass)
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        
        // 2. 选中项颜色 (金色 - Black Gold)
        let goldColor = UIColor(red: 212/255, green: 175/255, blue: 55/255, alpha: 1.0)
        
        let itemAppearance = UITabBarItemAppearance()
        
        // 普通状态 (未选中) - 灰色
        itemAppearance.normal.iconColor = UIColor.systemGray
        itemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.systemGray]
        
        // 选中状态 - 金色
        itemAppearance.selected.iconColor = goldColor
        itemAppearance.selected.titleTextAttributes = [.foregroundColor: goldColor]
        
        appearance.stackedLayoutAppearance = itemAppearance
        appearance.inlineLayoutAppearance = itemAppearance
        appearance.compactInlineLayoutAppearance = itemAppearance
        
        // 应用外观配置
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                ChatListView()
            }
            .tabItem {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                Text("Message")
            }
            .tag(Tab.message)
            
            NavigationStack {
                GroupListView()
            }
            .tabItem {
                Image(systemName: "person.3.fill")
                Text("Group")
            }
            .tag(Tab.group)
        }
        // 强制深色模式以配合 Black Gold 主题
        .preferredColorScheme(.dark)
        // 强调色 (Tint Color) 也会影响 TabView 选中态，再设置一次以防万一
        .accentColor(Color(red: 212/255, green: 175/255, blue: 55/255))
    }
}

