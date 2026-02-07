/*
FILE-GUIDE: ChatListView.swift
- 聊天会话列表 UI。
- 点击某个用户会创建并进入对应 ChatRoomView。
- 页面展示逻辑：正常列表、空态 loading、空态错误重试。
- 数据刷新入口：onAppear + pull-to-refresh。
*/

import SwiftUI
import Kingfisher

/// 聊天列表页
struct ChatListView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @ObservedObject var viewModel: ChatListViewModel
    let makeChatViewModel: (User, Int?) -> ChatViewModel
    
    var body: some View {
        ZStack {
            List(viewModel.users) { user in
                NavigationLink(destination: ChatRoomView(
                    viewModel: makeChatViewModel(user, authViewModel.currentUser?.id)
                )) {
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

            if viewModel.isLoading && viewModel.users.isEmpty {
                ProgressView("Loading conversations...")
                    .tint(.white)
                    .foregroundColor(.white)
            } else if let error = viewModel.errorMessage, viewModel.users.isEmpty {
                VStack(spacing: 12) {
                    Text(error)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)

                    Button("Retry") {
                        Task {
                            await viewModel.fetchUsers(currentUserId: authViewModel.currentUser?.id)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
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
        .refreshable {
            await viewModel.fetchUsers(currentUserId: authViewModel.currentUser?.id)
        }
        .onAppear {
            Task {
                await viewModel.fetchUsers(currentUserId: authViewModel.currentUser?.id)
            }
        }
    }
}

struct ChatListView_Preview: PreviewProvider {
    static var previews: some View {
        let container = AppContainer(
            apiClient: APIClient(),
            webSocketService: WebSocketService.shared,
            sessionStorage: InMemorySessionStorage()
        )
        let mockVM = container.chatListViewModel
        mockVM.loadMockData() // <--- 关键！手动塞入数据
        
        return NavigationStack {
            ChatListView(
                viewModel: mockVM,
                makeChatViewModel: { receiver, currentUserId in
                    container.makeChatViewModel(receiver: receiver, currentUserId: currentUserId)
                }
            )
        }
        .environmentObject(container)
        .environmentObject(container.authViewModel)
        .environmentObject(container.sessionStore)
        .preferredColorScheme(.dark) // 强制深色模式
    }
}
