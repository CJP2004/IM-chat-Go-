package ws

import (
	"encoding/json"
	"im-chat/internal/service"
	"log"
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

			if msg.Type == "read_ack" {
				// 如果是已读回执
				// 1. 更新数据库：标记 Sender(A) 已读了 Receiver(B) 发的消息
				// 所以是标记：Sender_id = Receiver(B), Receiver_id = Sender(A) 的消息为已读
				err := messageService.MarkMessagesRead(msg.ReceiverID, msg.SenderID)
				if err != nil {
					log.Printf("mark read failed: sender=%d receiver=%d err=%v", msg.ReceiverID, msg.SenderID, err)
					continue
				}

				// 已读回执仅通知被回执的一方
				h.pushToUser(msg.ReceiverID, msg)
				continue
			} else {
				// 2. 如果是普通消息，持久化到数据库
				saved, err := messageService.SaveMessage(msg.SenderID, msg.ReceiverID, msg.Content, msg.Type, msg.MediaURL)
				if err != nil {
					log.Printf("save message failed: sender=%d receiver=%d err=%v", msg.SenderID, msg.ReceiverID, err)
					continue
				}
				msg.MessageID = saved.ID
			}

			// 将消息转发给接收方
			h.pushToUser(msg.ReceiverID, msg)
			// 同时回执给发送方（用于前端用 clientMessageId / messageId 确认乐观消息）
			if msg.SenderID != msg.ReceiverID {
				h.pushToUser(msg.SenderID, msg)
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

func (h *Hub) pushToUser(userID uint, msg *WsMessage) {
	client, ok := h.UserClients[userID]
	if !ok {
		return
	}

	bytes, err := json.Marshal(msg)
	if err != nil {
		log.Printf("marshal ws message failed: user=%d err=%v", userID, err)
		return
	}

	select {
	case client.Send <- bytes:
	default:
		close(client.Send)
		delete(h.Clients, client)
		delete(h.UserClients, client.ID)
	}
}
