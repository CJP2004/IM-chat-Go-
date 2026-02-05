import Foundation
import Starscream
import Combine

/// WebSocket 服务管理类 (Starscream 版)
/// 负责处理与后端的实时连接、消息收发
class WebSocketService: ObservableObject {
    static let shared = WebSocketService()
    
    private var socket: WebSocket?
    
    // 使用 PassthroughSubject 将接收到的消息广播给订阅者 (ViewModels)
    var messageSubject = PassthroughSubject<Message, Never>()
    
    @Published var isConnected: Bool = false
    
    private init() {}
    
    /// 连接 WebSocket
    /// - Parameter userId: 当前用户 ID
    func connect(userId: Int) {
        // 如果已经连接且是同一个用户，不需要重连
        if isConnected { return }
        
        guard let url = URL(string: "\(Constants.wsURL)?userId=\(userId)") else { return }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        
        socket = WebSocket(request: request)
        socket?.delegate = self
        socket?.connect()
        
        print("Starscream: Connecting to \(url.absoluteString)...")
    }
    
    /// 断开连接
    func disconnect() {
        socket?.disconnect()
        socket = nil
        self.isConnected = false
    }
    
    /// 发送消息
    /// - Parameter message: 消息对象
    func sendMessage(_ message: Message) {
        guard let data = try? JSONEncoder().encode(message) else { return }
        guard let jsonString = String(data: data, encoding: .utf8) else { return }
        
        socket?.write(string: jsonString)
    }
}

// MARK: - WebSocketDelegate
extension WebSocketService: WebSocketDelegate {
    func didReceive(event: WebSocketEvent, client: WebSocketClient) {
        switch event {
        case .connected(let headers):
            print("Starscream: Connected! Headers: \(headers)")
            DispatchQueue.main.async {
                self.isConnected = true
            }
            
        case .disconnected(let reason, let code):
            print("Starscream: Disconnected: \(reason) with code: \(code)")
            DispatchQueue.main.async {
                self.isConnected = false
            }
            
        case .text(let string):
            handleIncomingText(string)
            
        case .binary(let data):
            print("Starscream: Received data: \(data.count)")
            
        case .error(let error):
            print("Starscream: Error: \(String(describing: error))")
            DispatchQueue.main.async {
                self.isConnected = false
            }
            
        case .cancelled:
            print("Starscream: Cancelled")
            DispatchQueue.main.async {
                self.isConnected = false
            }
            
        case .ping, .pong, .viabilityChanged, .reconnectSuggested:
            break
        case .peerClosed:
            break
        default:
            break
        }
    }
    
    /// 处理接收到的 JSON 文本
    private func handleIncomingText(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }
        
        do {
            let message = try JSONDecoder().decode(Message.self, from: data)
            // 在主线程发送更新
            DispatchQueue.main.async {
                self.messageSubject.send(message)
            }
        } catch {
            print("Failed to decode WS message: \(error)")
        }
    }
}
