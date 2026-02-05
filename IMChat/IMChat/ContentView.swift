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
