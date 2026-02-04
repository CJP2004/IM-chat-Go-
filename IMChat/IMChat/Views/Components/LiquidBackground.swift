import SwiftUI

/// 液态流动背景组件 (The Lava Lamp Effect)
/// 使用原生 SwiftUI 形状 + 高斯模糊 + 动画实现
struct LiquidBackground: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            // 基础背景色
            Color("BackgroundColor", bundle: nil) // 如果没有定义 asset 颜色，可以用系统色
                .ignoresSafeArea()
                .overlay(Color.black.opacity(0.1)) //稍微压暗一点
            
            // 流动的光斑 1 (紫色)
            Circle()
                .fill(Color.purple.opacity(0.4))
                .frame(width: 300, height: 300)
                .blur(radius: 60)
                .offset(x: animate ? -100 : 100, y: animate ? -50 : 50)
                .animation(
                    Animation.easeInOut(duration: 7).repeatForever(autoreverses: true),
                    value: animate
                )
            
            // 流动的光斑 2 (蓝色)
            Circle()
                .fill(Color.blue.opacity(0.4))
                .frame(width: 300, height: 300)
                .blur(radius: 60)
                .offset(x: animate ? 100 : -100, y: animate ? 100 : -100)
                .animation(
                    Animation.easeInOut(duration: 5).repeatForever(autoreverses: true),
                    value: animate
                )
            
            // 流动的光斑 3 (青色)
            Circle()
                .fill(Color.cyan.opacity(0.4))
                .frame(width: 250, height: 250)
                .blur(radius: 50)
                .offset(x: animate ? -50 : 150, y: animate ? 150 : -50)
                .animation(
                    Animation.easeInOut(duration: 6).repeatForever(autoreverses: true),
                    value: animate
                )
        }
        .onAppear {
            animate.toggle()
        }
        .ignoresSafeArea()
    }
}

struct LiquidBackground_Previews: PreviewProvider {
    static var previews: some View {
        LiquidBackground()
    }
}
