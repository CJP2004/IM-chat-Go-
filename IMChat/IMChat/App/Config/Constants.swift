/*
FILE-GUIDE: Constants.swift
- 全局网络地址配置：HTTP 基地址和 WebSocket 地址。
- 前后端联调失败时，先核对这里的 IP/端口是否与后端一致。
- 建议后续改为从环境配置读取，避免硬编码。
*/

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
