import Foundation

/// 全局常量定义
struct Constants {
    // ⚠️ 注意：请将此 IP 地址改为你电脑的局域网 IP
    // 如果你在模拟器运行，且后端在同一台电脑，通常可以使用 "localhost" 或 "127.0.0.1"
    // 但如果是真机调试，必须使用局域网 IP
    static let serverIP = "192.168.0.100"
    static let serverPort = "2222"
    
    static var baseURL: String {
        return "http://\(serverIP):\(serverPort)"
    }
    
    static var wsURL: String {
        return "ws://\(serverIP):\(serverPort)/ws"
    }
}
