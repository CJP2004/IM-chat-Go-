import SwiftUI
import Kingfisher

/// 聊天列表页
struct ChatListView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // 改成不直接初始化
    @StateObject private var viewModel: ChatListViewModel

    // 1. 第一个初始化方法：给 App 正常运行时使用 (自动创建新的 ViewModel)
        @MainActor
        init() {
            // 在这里创建，就处于 @MainActor 的保护之下了，编译器不会报错
            _viewModel = StateObject(wrappedValue: ChatListViewModel())
        }

        // 2. 第二个初始化方法：给 Preview 预览或测试使用 (允许注入假数据)
        @MainActor
        init(viewModel: ChatListViewModel) {
            _viewModel = StateObject(wrappedValue: viewModel)
        }
    
    var body: some View {
        List(viewModel.users) { user in
            NavigationLink(destination: ChatRoomView(receiver: user)) {
                HStack(spacing: 12) {
                    // 头像 (使用 Kingfisher)
                    KFImage(URL(string: user.avatar))
                        .resizable()
                        .placeholder {
                            ZStack {
                                Color.gray.opacity(0.3)
                                Image(systemName: "person.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30, height: 30) // 这里的尺寸相对于圆圈大小需适中
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                        .cacheMemoryOnly()
                        .fade(duration: 0.25)
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(user.username)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(user.lastMessage ?? user.tagline ?? "No messages")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    if let time = user.lastMessageTime {
                        Text(DateHelper.formatMessageTime(time))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.vertical, 4)
                .listRowBackground(Color.black) // 列表行背景
            }
        }
        .listStyle(PlainListStyle())
        .scrollContentBackground(.hidden)   // 隐藏列表默认背景
        .background(Color.black)            // 整体纯黑背景
        .navigationTitle("Message")
        // iOS 16+ 虽然默认跟随，但显式设置 .preferredColorScheme(.dark) 可以强制
        .preferredColorScheme(.dark)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    authViewModel.logout()
                }) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .foregroundColor(.white)
                        .offset(x: 2) // 视觉修正：向右微调以居中
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.fetchUsers()
            }
        }
    }
}

struct ChatListView_Preview: PreviewProvider {
    static var previews: some View {
        // 1. 创建 VM 并加载假数据
        let mockVM = ChatListViewModel()
        mockVM.loadMockData() // <--- 关键！手动塞入数据
        
        // 2. 必须包在 NavigationStack 里，不然看不到标题栏
        return NavigationStack {
            ChatListView(viewModel: mockVM) // <--- 把假 VM 传进去
        }
        .environmentObject(AuthViewModel()) // 注入环境对象防止崩溃
        .preferredColorScheme(.dark) // 强制深色模式
    }
}
