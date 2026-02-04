import SwiftUI
import ProgressHUD

/// 登录视图
struct LoginView: View {
    // 使用 EnvironmentObject 共享状态

    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var username = ""
    @State private var password = ""
    
    var body: some View {
        ZStack {
            // 背景色
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Logo 区域
                VStack(spacing: 10) {
                    Image(systemName: "message.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.orange)
                    
                    Text("IM Chat")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                .padding(.top, 50)
                
                // 表单区域
                VStack(spacing: 20) {
                    TextField("用户名", text: $username)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .textInputAutocapitalization(.never)
                    
                    SecureField("密码", text: $password)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                // 错误提示
                if let errorMessage = authViewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                // 登录按钮
                Button(action: {
                    Task {
                        ProgressHUD.animate("登录中...")
                        await authViewModel.login(username: username, password: password)
                        ProgressHUD.remove()
                    }
                }) {
                    if authViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("登录")
                            .fontWeight(.bold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal)
                .disabled(authViewModel.isLoading)
                
                Spacer()
            }
            .padding()
        }
    }
}

// 预览辅助
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AuthViewModel())
    }
}
