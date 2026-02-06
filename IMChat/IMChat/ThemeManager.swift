import SwiftUI
import UIKit

/// 主题管理器：统一黑金主题色与玻璃质感风格
enum ThemeManager {
    /// 主题主色（黑金）
    static let goldHex = "#D4AF37"
}

extension Color {
    /// 语义化主题色命名空间
    static let theme = ThemePalette()

    struct ThemePalette {
        /// 主色：黑金
        let gold = Color(red: 212 / 255, green: 175 / 255, blue: 55 / 255)
        /// 高光金
        let goldLight = Color(red: 245 / 255, green: 220 / 255, blue: 120 / 255)
        /// 深金
        let goldDeep = Color(red: 180 / 255, green: 130 / 255, blue: 25 / 255)
        /// 深黑背景
        let background = Color.black
        /// 玻璃质感（适用于浮层、卡片）
        let glassEffect: Material = .ultraThinMaterial

        /// 金色渐变（按钮、气泡等）
        var goldGradient: LinearGradient {
            LinearGradient(
                colors: [goldLight, gold, goldDeep],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

extension UIColor {
    /// UIKit 语义化主题色命名空间
    static let theme = ThemePalette()

    struct ThemePalette {
        /// 主色：黑金
        let gold = UIColor(red: 212 / 255, green: 175 / 255, blue: 55 / 255, alpha: 1)
        /// 高光金
        let goldLight = UIColor(red: 245 / 255, green: 220 / 255, blue: 120 / 255, alpha: 1)
        /// 深金
        let goldDeep = UIColor(red: 180 / 255, green: 130 / 255, blue: 25 / 255, alpha: 1)
        /// 深黑背景
        let background = UIColor.black
        /// 玻璃质感（UIKit 兜底色）
        let glassEffect = UIColor.white.withAlphaComponent(0.08)
    }
}
