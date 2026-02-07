/*
FILE-GUIDE: ProfileView.swift
- 个人页 UI，包含头像、标签、统计卡片与退出登录入口。
- 头像点击后弹出相机/相册选择，再调用 ViewModel 上传。
- 本文件主要是界面呈现与交互编排。
*/

import SwiftUI
import UIKit
import Kingfisher

// MARK: - 主视图 ProfileView
struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @ObservedObject var viewModel: ProfileViewModel

    @State private var showAvatarOptions = false
    @State private var showImagePicker = false
    @State private var pickerSource: UIImagePickerController.SourceType = .photoLibrary

    // 原生弹窗在大屏设备会以 Popover 展示，调整这个值可下移锚点
    private let avatarDialogYOffset: CGFloat = 70
    
    var body: some View {
        ZStack {
            // 1. 沉浸式背景
            if let user = authViewModel.currentUser {
                KFImage(URL(string: user.avatar))
                    .resizable()
                    .placeholder { Color.black }
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .blur(radius: 60)
                    .overlay(Color.black.opacity(0.4))
                    .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
            }

            // 2. 主要内容层
            VStack(spacing: 0) {
                Spacer().frame(height: 20)
                
                if let user = authViewModel.currentUser {
                    // --- 头像区域 ---
                    ZStack {
                        Button(action: {
                            showAvatarOptions = true
                        }) {
                            ZStack {
                                // 光晕
                                Circle()
                                    .fill(Color.theme.gold.opacity(0.4))
                                    .frame(width: 170, height: 170)
                                    .blur(radius: 30)
                                
                                KFImage(URL(string: user.avatar))
                                    .resizable()
                                    .placeholder {
                                        Image(systemName: "person.fill")
                                            .resizable()
                                            .padding(40)
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                    .scaledToFill()
                                    .frame(width: 140, height: 140)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle().stroke(Color.theme.gold, lineWidth: 2)
                                    )
                                    .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
                                
                                if viewModel.isUploading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(1.1)
                                }
                                
                                // 相机图标
                                VStack {
                                    Spacer()
                                    HStack {
                                        Spacer()
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(.white)
                                            .padding(8)
                                            .background(.ultraThinMaterial)
                                            .background(Color.theme.gold.opacity(0.5))
                                            .clipShape(Circle())
                                            .overlay(
                                                Circle().stroke(Color.white.opacity(0.3), lineWidth: 1)
                                            )
                                            .offset(x: -10, y: -5)
                                    }
                                }
                                .frame(width: 140, height: 140)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())

                        // 原生弹窗锚点：用透明视图下移锚点位置
                        Color.clear
                            .frame(width: 1, height: 1)
                            .offset(y: avatarDialogYOffset)
                            .allowsHitTesting(false)
                            .confirmationDialog("Change profile picture", isPresented: $showAvatarOptions, titleVisibility: .visible) {
                                Button("Album") {
                                    pickerSource = .photoLibrary
                                    showImagePicker = true
                                }
                                Button("camera") {
                                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                                        pickerSource = .camera
                                        showImagePicker = true
                                    } else {
                                        viewModel.errorMessage = "The current device does not support the camera."
                                    }
                                }
                                Button("Cancel", role: .cancel) {}
                            }
                    }
                    
                    Spacer().frame(height: 20)
                    
                    // --- 用户名 ---
                    Text(user.username)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    
                    // --- 胶囊标签 ---
                    HStack(spacing: 12) {
                        TagCapsule(text: "Designer", icon: "paintbrush.fill")
                        TagCapsule(text: "VIP", icon: "star.fill", color: Color.theme.gold)
                    }
                    .padding(.top, 15)
                    
                    Spacer().frame(height: 40)
                    
                    // --- 统计数据卡片 ---
                    // 这里使用了 maxWidth: .infinity 配合 padding，会自动平分宽度
                    // --- 统计数据卡片 ---
                    // 使用 spacing: 8 和 padding: 16 确保在小屏上也能放下
                    HStack(spacing: 8) {
                        StatCard(title: "Friends", value: "128")
                        StatCard(title: "Groups", value: "12")
                        StatCard(title: "Days", value: "365")
                    }
                    .padding(.horizontal, 0)
                    .frame(maxWidth: 420)

                    
                    Spacer()
                    Spacer().frame(height: 50)
                }
            }
            .frame(maxWidth: .infinity) // 确保 VStack 宽度受限，防止溢出
        }
        .preferredColorScheme(.dark)
        .toolbarBackground(.hidden, for: .tabBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        
        // --- 右上角退出按钮 ---
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
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(
                sourceType: pickerSource,
                onImagePicked: { image in
                    showImagePicker = false
                    Task {
                        if let avatarURL = await viewModel.uploadAvatar(
                            image: image,
                            token: authViewModel.token
                        ) {
                            authViewModel.updateCurrentUserAvatar(url: avatarURL)
                        }
                    }
                },
                onCancel: {
                    showImagePicker = false
                }
            )
            .ignoresSafeArea()
        }
        .alert("提示", isPresented: Binding<Bool>(
            get: { viewModel.errorMessage != nil },
            set: { _ in viewModel.clearError() }
        )) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

// 自定义按钮样式，确保移除 NavigationBar 默认的背景效果
struct ToolbarButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

// MARK: - 子组件定义

/// 胶囊标签组件
struct TagCapsule: View {
    let text: String
    var icon: String? = nil
    var color: Color = .white
    
    var body: some View {
        HStack(spacing: 6) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.caption)
            }
            Text(text)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .foregroundColor(color == .white ? .white : .black)
        .background {
            if color == .white {
                Rectangle()
                    .fill(.ultraThinMaterial)
            } else {
                color
            }
        }
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
        )
    }
}

/// 统计卡片组件
struct StatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5) // 允许缩小字体以防宽度溢出
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(minWidth: 0, maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.3), .white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}

// 预览代码
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        let container = AppContainer(
            apiClient: APIClient(),
            webSocketService: WebSocketService.shared,
            sessionStorage: InMemorySessionStorage()
        )
        let previewUser = User(
            id: 1,
            username: "Angela",
            avatar: "https://i.pravatar.cc/300?u=5",
            tagline: "Vaganova Method",
            lastMessage: nil,
            lastMessageTime: nil
        )
        let previewStorage = InMemorySessionStorage()
        previewStorage.saveSession(token: "preview-token", user: previewUser)
        let previewSessionStore = AppSessionStore(storage: previewStorage)
        let authViewModel = AuthViewModel(
            sessionStore: previewSessionStore,
            authRepository: container.authRepository,
            webSocketService: container.webSocketService
        )
        
        return ProfileView(viewModel: container.profileViewModel)
            .environmentObject(container)
            .environmentObject(authViewModel)
            .environmentObject(previewSessionStore)
    }
}
