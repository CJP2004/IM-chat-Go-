package ws

import (
	"encoding/json"
	"im-chat/internal/service"
)

// messageService 消息服务实例
var messageService = new(service.MessageService)

// Hub 维护活跃的客户端连接并将消息广播给客户端
// 类似于 Java 中的单例 Manager 类
type Hub struct {
	// Registered clients.
	// 所有的在线客户端 (Set结构，key是Client指针，value是bool)
	Clients map[*Client]bool

	// 维护 UserID 到 Client 的映射，方便点对点私聊
	UserClients map[uint]*Client

	// Inbound messages from the clients.
	// 广播通道：原本用于广播所有消息，现在主要用于群发或系统通知
	Broadcast chan []byte

	// 私聊通道：接收定向消息
	// Channel (通道) 是 Go 并发核心，类似于一个线程安全的阻塞队列 (BlockingQueue)
	Direct chan *WsMessage

	// Register requests from the clients.
	// 注册通道：有新连接时，Client 会发给自己到这里
	Register chan *Client

	// Unregister requests from the clients.
	// 注销通道：连接断开时，发到这里
	Unregister chan *Client
}

// NewHub 创建一个新的 Hub 实例
func NewHub() *Hub {
	return &Hub{
		Broadcast:   make(chan []byte),
		Direct:      make(chan *WsMessage),
		Register:    make(chan *Client),
		Unregister:  make(chan *Client),
		Clients:     make(map[*Client]bool),
		UserClients: make(map[uint]*Client),
	}
}

// Run 启动 Hub 的主处理循环
// 这是一个无限循环，通常在一个单独的 Goroutine 中运行
func (h *Hub) Run() {
	for {
		// select 语句类似于 Switch，但是用于 Channel
		// 它会阻塞等待，直到其中一个 case 可以执行 (有消息传来)
		select {
		case client := <-h.Register:
			// 1. 处理注册：将客户端加入 Map
			h.Clients[client] = true
			if client.ID != 0 {
				h.UserClients[client.ID] = client
			}
		case client := <-h.Unregister:
			// 2. 处理注销：从 Map 移除，并关闭该客户端的发送通道
			if _, ok := h.Clients[client]; ok {
				delete(h.Clients, client)
				if client.ID != 0 {
					delete(h.UserClients, client.ID)
				}
				close(client.Send)
			}

		case msg := <-h.Direct:
			// 3. 处理私聊消息

			// 通过 Service 层持久化消息到数据库
			// 注意：这里简单同步入库，高并发下建议使用消息队列或异步处理
			messageService.SaveMessage(msg.SenderID, msg.ReceiverID, msg.Content, msg.Type, msg.MediaURL)

			// 根据消息中的 ReceiverID 找到目标客户端
			if client, ok := h.UserClients[msg.ReceiverID]; ok {
				// 将结构体序列化回 JSON 字节
				bytes, _ := json.Marshal(msg)
				select {
				case client.Send <- bytes: // 发送给目标客户端
				default:
					// 如果发送失败 (缓冲区满/断开)，则关闭连接
					close(client.Send)
					delete(h.Clients, client)
					delete(h.UserClients, client.ID)
				}
			}
		case message := <-h.Broadcast:
			// 4. 处理广播消息 (给所有人)
			for client := range h.Clients {
				select {
				case client.Send <- message:
				default:
					close(client.Send)
					delete(h.Clients, client)
				}
			}
		}
	}
}
