/*
FILE-GUIDE: ChatRoomView.swift
- 单聊会话 UI，包含消息区、顶部栏、输入栏。
- 关键交互：
  1) 首次进入自动滚到底部
  2) 新消息到来自动滚到底部
  3) 仅“向上翻历史”时保持当前位置
- 该文件重在滚动体验和布局细节，业务状态仍由 ChatViewModel 驱动。
*/

import SwiftUI
import Kingfisher

/// 聊天室视图
struct ChatRoomView: View {
    private let bottomAnchorId = "chat-bottom-anchor"

    @StateObject private var viewModel: ChatViewModel
    @FocusState private var isInputFocused: Bool
    @Environment(\.dismiss) private var dismiss
    
    init(viewModel: ChatViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        GeometryReader { proxy in
            let topInset = proxy.safeAreaInsets.top
            let bubbleMaxWidth = proxy.size.width * 0.7

            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    // 消息列表
                    ScrollViewReader { scrollProxy in
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                if viewModel.isHistoryLoading && !viewModel.messages.isEmpty {
                                    ProgressView()
                                        .tint(.white)
                                        .padding(.vertical, 6)
                                }

                                ForEach(viewModel.messages) { message in
                                    MessageBubble(
                                        message: message,
                                        isCurrentUser: message.senderId != viewModel.receiver.id,
                                        maxBubbleWidth: bubbleMaxWidth
                                    )
                                    .onAppear {
                                        viewModel.loadMoreHistoryIfNeeded(currentMessage: message)
                                    }
                                }
                                Color.clear
                                    .frame(height: 1)
                                    .id(bottomAnchorId)
                            }
                            .padding()
                        }
                        .padding(.top, topInset + 8)
                        .onAppear {
                            scrollToBottom(using: scrollProxy, animated: false)
                        }
                        .onChange(of: viewModel.messages) { oldMessages, newMessages in
                            guard !didOnlyPrependHistory(oldMessages: oldMessages, newMessages: newMessages) else {
                                return
                            }
                            scrollToBottom(using: scrollProxy, animated: true)
                        }
                        .overlay {
                            if viewModel.isHistoryLoading && viewModel.messages.isEmpty {
                                ProgressView("Loading messages...")
                                    .tint(.white)
                                    .foregroundColor(.white)
                            } else if let error = viewModel.historyErrorMessage, viewModel.messages.isEmpty {
                                VStack(spacing: 10) {
                                    Text(error)
                                        .font(.subheadline)
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(.gray)
                                    Button("Retry") {
                                        Task {
                                            await viewModel.fetchHistory()
                                        }
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                                .padding()
                            }
                        }
                        .overlay(alignment: .top) {
                            if let error = viewModel.historyErrorMessage, !viewModel.messages.isEmpty {
                                HStack(spacing: 8) {
                                    Text(error)
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.85))
                                        .lineLimit(1)
                                    Button("Retry") {
                                        viewModel.retryLoadMoreHistory()
                                    }
                                    .font(.caption.weight(.semibold))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.black.opacity(0.7))
                                .clipShape(Capsule())
                                .padding(.top, 6)
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

                ChatHeaderView(
                    receiver: viewModel.receiver,
                    topInset: topInset,
                    onBack: { dismiss() },
                    onAction: {}
                )
            }
            .background(Color.theme.background)
            .ignoresSafeArea(edges: .top)
        }
        // 隐藏底部 Tab Bar (iOS 16+)
        .toolbar(.hidden, for: .tabBar)
        .toolbar(.hidden, for: .navigationBar)
        // 确保深色背景
        .background(Color.theme.background)
        .preferredColorScheme(.dark)
    }

    private func scrollToBottom(using proxy: ScrollViewProxy, animated: Bool) {
        DispatchQueue.main.async {
            if animated {
                withAnimation(.easeOut(duration: 0.25)) {
                    proxy.scrollTo(bottomAnchorId, anchor: .bottom)
                }
            } else {
                proxy.scrollTo(bottomAnchorId, anchor: .bottom)
            }
        }
    }

    private func didOnlyPrependHistory(oldMessages: [ChatMessage], newMessages: [ChatMessage]) -> Bool {
        guard newMessages.count > oldMessages.count else { return false }
        guard oldMessages.last?.stableId == newMessages.last?.stableId else { return false }
        guard oldMessages.first?.stableId != newMessages.first?.stableId else { return false }
        return true
    }
}

/// 消息气泡组件
struct MessageBubble: View {
    let message: ChatMessage
    let isCurrentUser: Bool
    let maxBubbleWidth: CGFloat
    
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
                        .frame(maxWidth: maxBubbleWidth, alignment: isCurrentUser ? .trailing : .leading)
                }
            }
            
            if !isCurrentUser { Spacer() }
        }
        .id(message.id) // 用于滚动定位
    }
}
