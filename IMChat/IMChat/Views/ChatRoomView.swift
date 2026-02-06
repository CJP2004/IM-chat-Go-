import SwiftUI
import Kingfisher

/// 聊天室视图
struct ChatRoomView: View {
    @StateObject private var viewModel: ChatViewModel
    @FocusState private var isInputFocused: Bool
    
    init(receiver: User) {
        _viewModel = StateObject(wrappedValue: ChatViewModel(receiver: receiver))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 消息列表
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message, isCurrentUser: message.senderId != viewModel.receiver.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages) { _ in
                    // 新消息自动滚动到底部
                    if let lastMsg = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMsg.id, anchor: .bottom)
                        }
                    }
                }
            }
            .onTapGesture {
                isInputFocused = false
            }
            
            // 输入栏
            HStack(spacing: 10) {
                TextField("Typing Message...", text: $viewModel.newMessageText)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.theme.glassEffect)
                    )
                    .focused($isInputFocused)
                    .submitLabel(.send)
                    .onSubmit {
                        viewModel.sendMessage()
                    }
                
                Button(action: {
                    viewModel.sendMessage()
                }) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Color.theme.gold)
                }
            }
            .padding()
            .background(Color.theme.background)
            .shadow(color: Color.white.opacity(0.1), radius: 5, x: 0, y: -5)
        }
        .navigationTitle(viewModel.receiver.username)
        .navigationBarTitleDisplayMode(.inline)
        // 隐藏底部 Tab Bar (iOS 16+)
        .toolbar(.hidden, for: .tabBar)
        // 确保深色背景
        .background(Color.theme.background)
        .preferredColorScheme(.dark)
    }
}

/// 消息气泡组件
struct MessageBubble: View {
    let message: Message
    let isCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isCurrentUser { Spacer() }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading) {
                if message.type == "image", let mediaUrl = message.mediaUrl, !mediaUrl.isEmpty {
                    // 图片消息
                    KFImage(URL(string: mediaUrl))
                        .resizable()
                        .placeholder {
                            ProgressView()
                                .frame(width: 100, height: 100)
                                .background(Color.gray.opacity(0.1))
                        }
                        .scaledToFit()
                        .frame(maxWidth: 200, maxHeight: 300)
                        .cornerRadius(12)
                } else {
                    // 文本消息
                    Text(message.content)
                        .padding(12)
                        .background(
                            Group {
                                if isCurrentUser {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.theme.goldGradient)
                                } else {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color(.systemGray5))
                                }
                            }
                        )
                        .foregroundColor(isCurrentUser ? .white : .primary)
                }
            }
            
            if !isCurrentUser { Spacer() }
        }
        .id(message.id) // 用于滚动定位
    }
}
