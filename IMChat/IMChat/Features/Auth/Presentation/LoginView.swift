/*
FILE-GUIDE: LoginView.swift
- 登录/注册页面 UI。
- 页面内维护输入态（用户名、密码、注册模式），提交动作委托给 AuthViewModel。
- 该文件偏重视觉布局和交互动画，业务逻辑尽量保持在 ViewModel。
- 阅读建议：先看按钮 action，再回看表单状态是如何驱动 UI 的。
*/

import SwiftUI
import ProgressHUD

/// 登录视图
struct LoginView: View {
    // 使用 EnvironmentObject 共享状态

    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var username = ""
    @State private var password = ""
    @State private var isSignUp = false // 注册模式开关
    @State private var confirmPassword = ""
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 1. 纯黑整体背景
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 顶部背景图 (Top Image Fade)
                    ZStack(alignment: .bottom) {
                        Image(isSignUp ? "BackgroundSignUp" : "BackgroundLogin")
                            .resizable()
                            .scaledToFill()
                            .frame(
                                width: geometry.size.width,
                                height: geometry.size.height * 0.65
                            ) // 占据屏幕 65% (约 2/3)
                            .clipped()
                        
                        // 渐变遮罩 (从透明到黑色，高度增加以覆盖更多区域)
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: .clear, location: 0),
                                .init(color: .black.opacity(0.8), location: 0.7), // 加深过渡
                                .init(color: .black, location: 1.0)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 300) // 增加渐变区域高度，让文字更清晰
                    }
    //                .ignoresSafeArea()
                    .ignoresSafeArea(edges: .top)
                    
                    Spacer() // 推挤内容
                }
                .ignoresSafeArea()
                .frame(
                    width: geometry.size.width,
                    height: geometry.size.height,
                    alignment: .top
                )
                
                VStack(spacing: 30) {
                    Spacer()
                    Spacer() // 增加顶部空间，让内容整体下移
                    
                    // Logo / 标题区域
                    VStack(spacing: 10) {
                        Text("Shadow Talk")
                            .font(.system(size: 42, weight: .heavy, design: .rounded)) // 字体加大一号
                            .foregroundColor(.white)
                            .tracking(2)
                            .shadow(color: .black.opacity(0.8), radius: 10, x: 0, y: 5) // 增加重阴影，解决看不清的问题
                        
                        Text("Connect with friends")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.9))
                            .shadow(color: .black.opacity(0.8), radius: 5, x: 0, y: 2)
                    }
                    .padding(.bottom, 20)
                    
                    // 表单区域
                    VStack(spacing: 20) {
                        // 用户名输入框
                        ZStack(alignment: .leading) {
                            if username.isEmpty {
                                Text("Username")
                                    .foregroundColor(Color.white.opacity(0.6)) // 显眼的灰色占位符
                                    .padding(.leading, 16)
                            }
                            TextField("", text: $username)
                                .padding()
                                .foregroundColor(.white)
                                .textInputAutocapitalization(.never)
                        }
                        .background(Color(white: 0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(white: 0.2), lineWidth: 1)
                        )
                        
                        // 密码输入框
                        ZStack(alignment: .leading) {
                            if password.isEmpty {
                                Text("Password")
                                    .foregroundColor(Color.white.opacity(0.6))
                                    .padding(.leading, 16)
                            }
                            SecureField("", text: $password)
                                .padding()
                                .foregroundColor(.white)
                        }
                        .background(Color(white: 0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(white: 0.2), lineWidth: 1)
                        )
                        
                        // 确认密码 (仅注册模式显示)
                        if isSignUp {
                            ZStack(alignment: .leading) {
                                if confirmPassword.isEmpty {
                                    Text("Confirm Password")
                                        .foregroundColor(Color.white.opacity(0.6))
                                        .padding(.leading, 16)
                                }
                                SecureField("", text: $confirmPassword)
                                    .padding()
                                    .foregroundColor(.white)
                            }
                            .background(Color(white: 0.1))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(white: 0.2), lineWidth: 1)
                            )
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    // .padding(.horizontal, 20) // Removed inner padding
                    .animation(.easeInOut, value: isSignUp)
                    
                    // 登录/注册按钮
                    Button(action: {
                        Task {
                            // 注册校验
                            if isSignUp && password != confirmPassword {
                                authViewModel.errorMessage = "Passwords do not match"
                                return
                            }
                            
                            let actionName = isSignUp ? "Validating..." : "Logging in..."
                            ProgressHUD.animate(actionName)
                            
                            if isSignUp {
                                await authViewModel.register(username: username, password: password)
                            } else {
                                await authViewModel.login(username: username, password: password)
                            }
                            
                            ProgressHUD.remove()
                        }
                    }) {
                        if authViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                        } else {
                            Text(isSignUp ? "Sign Up" : "Login")
                                .font(.headline)
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding()
                    .background(Color(red: 1.0, green: 0.82, blue: 0.24))
                    .foregroundColor(.black)
                    .cornerRadius(12)
                    .overlay(alignment: .bottom) {
                         if let errorMessage = authViewModel.errorMessage {
                             Text(errorMessage)
                                 .foregroundColor(.red)
                                 .font(.caption)
                                 .fixedSize(horizontal: false, vertical: true)
                                 .offset(y: 30) // 向下偏移，悬浮在按钮下方而不占用布局空间
                         }
                    }
                    
                    Spacer()
                    Spacer()
                    
                    // 底部切换模式
                    HStack {
                        Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                            .foregroundColor(.gray)
                        Button(action: {
                            withAnimation {
                                isSignUp.toggle()
                                authViewModel.errorMessage = nil
                            }
                        }) {
                            Text(isSignUp ? "Sign In" : "Sign Up")
                                .foregroundColor(Color(red: 1.0, green: 0.82, blue: 0.24))
                                .fontWeight(.bold)
                        }
                    }
                    .font(.footnote)
                }
                .padding(.horizontal, 32)
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .padding(.bottom, 20)     // 底部增加留白
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

// 预览辅助
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        let container = AppContainer(
            apiClient: APIClient(),
            webSocketService: WebSocketService.shared,
            sessionStorage: InMemorySessionStorage()
        )
        LoginView()
            .environmentObject(container.authViewModel)
            .environmentObject(container)
            .environmentObject(container.sessionStore)
    }
}
