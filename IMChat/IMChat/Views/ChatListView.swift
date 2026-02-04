import SwiftUI
import Kingfisher

/// 聊天列表页
struct ChatListView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = ChatListViewModel()
    
    var body: some View {
        List(viewModel.users) { user in
            NavigationLink(destination: ChatRoomView(receiver: user)) {
                HStack(spacing: 12) {
                    // 头像 (使用 Kingfisher)
                    KFImage(URL(string: user.avatar))
                        .resizable()
                        .placeholder {
                            Color.gray.opacity(0.3)
                        }
                        .cacheMemoryOnly()
                        .fade(duration: 0.25)
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(user.username)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if let tagline = user.tagline {
                            Text(tagline)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(PlainListStyle())
        .navigationTitle("消息")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    authViewModel.logout()
                }) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
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
