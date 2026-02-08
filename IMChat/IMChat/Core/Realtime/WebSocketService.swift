/*
FILE-GUIDE: WebSocketService.swift
- 全局实时通信服务（单例），负责连接管理与消息收发。
- 关键能力：自动重连、心跳保活、离线消息队列、连接状态发布。
- 认证方式：连接时携带 Bearer token 到请求头。
- ViewModel 通过 messageSubject 订阅实时消息，不直接操作底层 socket。
- 如果消息收不到：先查 connectionState，再查 token 是否有效。
*/

import Foundation
import Starscream
import Combine

/// WebSocket 服务管理类 (Starscream 版)
/// 负责处理与后端的实时连接、消息收发
class WebSocketService: ObservableObject {
    enum ConnectionState: Equatable {
        case disconnected
        case connecting
        case connected
        case reconnecting(attempt: Int)
    }

    static let shared = WebSocketService()
    
    private var socket: WebSocket?

    // 使用 PassthroughSubject 将接收到的消息广播给订阅者 (ViewModels)
    let messageSubject = PassthroughSubject<WSMessageDTO, Never>()

    @Published private(set) var connectionState: ConnectionState = .disconnected
    @Published private(set) var isConnected: Bool = false

    private var activeUserId: Int?
    private var activeToken: String?
    private var reconnectAttempts = 0
    private var shouldAutoReconnect = false
    private var reconnectWorkItem: DispatchWorkItem?
    private var heartbeatTimer: Timer?
    private var outboundQueue: [WSMessageDTO] = []

    private let maxReconnectAttempts = 6
    private let reconnectBaseDelay: TimeInterval = 1
    private let maxReconnectDelay: TimeInterval = 20
    private let heartbeatInterval: TimeInterval = 20

    /// 私有初始化，强制外部通过 `shared` 单例访问。
    private init() {}
    
    /// 连接 WebSocket
    /// - Parameters:
    ///   - userId: 当前用户 ID
    ///   - token: 登录态 token
    func connect(userId: Int, token: String?) {
        guard let token, !token.isEmpty else {
            disconnect()
            return
        }

        if activeUserId != userId || activeToken != token {
            teardownSocket()
            outboundQueue.removeAll()
        }
        activeUserId = userId
        activeToken = token
        shouldAutoReconnect = true
        reconnectAttempts = 0

        guard connectionState != .connecting else { return }
        if case .reconnecting = connectionState { return }
        if connectionState == .connected { return }

        openSocket(for: userId, token: token, isReconnect: false)
    }
    
    /// 断开连接
    func disconnect() {
        shouldAutoReconnect = false
        activeUserId = nil
        activeToken = nil
        reconnectAttempts = 0
        outboundQueue.removeAll()
        cancelReconnect()
        stopHeartbeat()
        teardownSocket()
        updateConnectionState(.disconnected)
    }
    
    /// 发送消息
    /// - Parameter message: 消息对象
    func sendMessage(_ message: WSMessageDTO) {
        if isConnected {
            writeMessage(message)
            return
        }

        // 连接未就绪时先入队，连上后自动冲刷
        outboundQueue.append(message)

        if let userId = activeUserId, shouldAutoReconnect {
            scheduleReconnectIfNeeded(for: userId)
        }
    }

    /// 创建并启动 socket 连接（支持首连与重连两种状态）。
    private func openSocket(for userId: Int, token: String, isReconnect: Bool) {
        guard let url = URL(string: Constants.wsURL) else {
            updateConnectionState(.disconnected)
            return
        }

        cancelReconnect()
        stopHeartbeat()
        teardownSocket()

        updateConnectionState(isReconnect ? .reconnecting(attempt: reconnectAttempts) : .connecting)

        var request = URLRequest(url: url)
        request.timeoutInterval = 8
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let socket = WebSocket(request: request)
        socket.delegate = self
        self.socket = socket
        socket.connect()
        print("Starscream: Connecting to \(url.absoluteString)...")
    }

    /// 安全释放现有 socket，避免重复 delegate 回调或脏连接。
    private func teardownSocket() {
        socket?.delegate = nil
        socket?.disconnect()
        socket = nil
    }

    /// 统一更新连接状态，并同步维护 `isConnected` 给 UI 绑定使用。
    private func updateConnectionState(_ state: ConnectionState) {
        DispatchQueue.main.async {
            self.connectionState = state
            self.isConnected = (state == .connected)
        }
    }

    /// 处理“断开类”事件：停止心跳并按策略决定是否重连。
    private func handleDisconnectLikeEvent() {
        stopHeartbeat()
        guard shouldAutoReconnect, let userId = activeUserId else {
            updateConnectionState(.disconnected)
            return
        }
        scheduleReconnectIfNeeded(for: userId)
    }

    /// 根据指数退避策略安排下一次重连任务。
    private func scheduleReconnectIfNeeded(for userId: Int) {
        guard shouldAutoReconnect else { return }
        guard reconnectWorkItem == nil else { return }
        guard reconnectAttempts < maxReconnectAttempts else {
            updateConnectionState(.disconnected)
            return
        }

        reconnectAttempts += 1
        let delay = min(reconnectBaseDelay * pow(2, Double(reconnectAttempts - 1)), maxReconnectDelay)
        updateConnectionState(.reconnecting(attempt: reconnectAttempts))

        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.reconnectWorkItem = nil
            guard self.shouldAutoReconnect, let token = self.activeToken else { return }
            self.openSocket(for: userId, token: token, isReconnect: true)
        }
        reconnectWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    /// 取消尚未执行的重连任务。
    private func cancelReconnect() {
        reconnectWorkItem?.cancel()
        reconnectWorkItem = nil
    }

    /// 启动周期性 ping 心跳，帮助服务端保持连接活跃并尽快感知断线。
    private func startHeartbeat() {
        stopHeartbeat()
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: heartbeatInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                guard self.connectionState == .connected else { return }
                self.socket?.write(ping: Data())
            }
        }
        RunLoop.main.add(heartbeatTimer!, forMode: .common)
    }

    /// 停止并销毁心跳定时器。
    private func stopHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
    }

    /// 连接恢复后批量发送离线期间暂存的消息队列。
    private func flushOutboundQueue() {
        guard !outboundQueue.isEmpty else { return }
        let pending = outboundQueue
        outboundQueue.removeAll()
        pending.forEach { writeMessage($0) }
    }

    /// 将消息编码为 JSON 文本并写入当前 socket。
    private func writeMessage(_ message: WSMessageDTO) {
        guard let data = try? JSONEncoder().encode(message),
              let jsonString = String(data: data, encoding: .utf8) else {
            return
        }
        socket?.write(string: jsonString)
    }
}

// MARK: - WebSocketDelegate
extension WebSocketService: WebSocketDelegate {
    /// 统一接收 Starscream 事件并分发到连接状态/消息处理逻辑。
    func didReceive(event: WebSocketEvent, client: WebSocketClient) {
        switch event {
        case .connected(let headers):
            print("Starscream: Connected! Headers: \(headers)")
            reconnectAttempts = 0
            updateConnectionState(.connected)
            startHeartbeat()
            flushOutboundQueue()
            
        case .disconnected(let reason, let code):
            print("Starscream: Disconnected: \(reason) with code: \(code)")
            handleDisconnectLikeEvent()
            
        case .text(let string):
            handleIncomingText(string)
            
        case .binary(let data):
            print("Starscream: Received data: \(data.count)")
            
        case .error(let error):
            print("Starscream: Error: \(String(describing: error))")
            handleDisconnectLikeEvent()
            
        case .cancelled:
            print("Starscream: Cancelled")
            handleDisconnectLikeEvent()
            
        case .reconnectSuggested:
            if let userId = activeUserId {
                scheduleReconnectIfNeeded(for: userId)
            }
        case .viabilityChanged(let isViable):
            if !isViable, let userId = activeUserId {
                scheduleReconnectIfNeeded(for: userId)
            }
        case .ping, .pong:
            break
        case .peerClosed:
            handleDisconnectLikeEvent()
        }
    }
    
    /// 处理接收到的 JSON 文本
    private func handleIncomingText(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }
        
        do {
            let message = try JSONDecoder().decode(WSMessageDTO.self, from: data)
            // 在主线程发送更新
            DispatchQueue.main.async {
                self.messageSubject.send(message)
            }
        } catch {
            print("Failed to decode WS message: \(error)")
        }
    }
}
