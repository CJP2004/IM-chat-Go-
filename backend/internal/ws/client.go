package ws

import (
	"log"
	"net/http"
	"encoding/json"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/gorilla/websocket"
)

const (
	// 定义一些超时时间
	writeWait      = 10 * time.Second
	pongWait       = 60 * time.Second
	pingPeriod     = (pongWait * 9) / 10
	maxMessageSize = 512
)

// upgrader 用于将 HTTP 连接升级为 WebSocket 连接
var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin: func(r *http.Request) bool {
		return true // 开发环境允许所有跨域请求
	},
}

// Client 代表一个中间人，连接 WebSocket 连接和 Hub
type Client struct {
	Hub *Hub
	ID  uint // 关联的用户 ID
	
	// The websocket connection.
	Conn *websocket.Conn

	// Buffered channel of outbound messages.
	// 发送通道：Hub 会把要发给这个人的消息写到这里 (Channel)
	// WritePump 会监听这里
	Send chan []byte
}

// ReadPump 循环读取客户端发来的消息
// 每个 Client 都有一个独立的 ReadPump Goroutine
func (c *Client) ReadPump() {
	defer func() {
		// 退出时注销并关闭连接
		c.Hub.Unregister <- c
		c.Conn.Close()
	}()
	c.Conn.SetReadLimit(maxMessageSize)
	c.Conn.SetReadDeadline(time.Now().Add(pongWait))
	// 设置心跳响应 (Pong) 处理器
	c.Conn.SetPongHandler(func(string) error { c.Conn.SetReadDeadline(time.Now().Add(pongWait)); return nil })
	
	for {
		// 阻塞读取 WebSocket 消息
		_, message, err := c.Conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				log.Printf("error: %v", err)
			}
			break
		}
		
		// 解析前端发来的 JSON 消息
		var wsMsg WsMessage
		if err := json.Unmarshal(message, &wsMsg); err != nil {
			log.Printf("error unmarshal: %v", err)
			continue
		}
		
		wsMsg.SenderID = c.ID // 强制标记发送者为当前用户，防止伪造

		// 根据是否有 ReceiverID 决定是私聊还是广播
		if wsMsg.ReceiverID != 0 {
			c.Hub.Direct <- &wsMsg
		} else {
			c.Hub.Broadcast <- message
		}
	}
}

// WritePump 循环将 Hub 发来的消息写入 WebSocket 连接
// 每个 Client 都有一个独立的 WritePump Goroutine
func (c *Client) WritePump() {
	ticker := time.NewTicker(pingPeriod) // 定时发送心跳 Ping
	defer func() {
		ticker.Stop()
		c.Conn.Close()
	}()
	for {
		select {
		case message, ok := <-c.Send:
			// 如果通道被关闭，说明 Hub 希望断开连接
			c.Conn.SetWriteDeadline(time.Now().Add(writeWait))
			if !ok {
				c.Conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}

			// 获取 WebSocket 写入器
			w, err := c.Conn.NextWriter(websocket.TextMessage)
			if err != nil {
				return
			}
			w.Write(message)

			// 如果 Send 通道里积压了多条消息，一次性写完，提高效率
			n := len(c.Send)
			for i := 0; i < n; i++ {
				w.Write(<-c.Send)
			}

			if err := w.Close(); err != nil {
				return
			}
		case <-ticker.C:
			// 定时发送 Ping 保持连接活跃
			c.Conn.SetWriteDeadline(time.Now().Add(writeWait))
			if err := c.Conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}

// ServeWs 处理 WebSocket 请求入口
func ServeWs(hub *Hub, c *gin.Context) {
	// 1. 将 HTTP 请求升级为 WebSocket 协议
	conn, err := upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		log.Println(err)
		return
	}
	
	// 2. 从 Query 参数获取当前用户 ID (后续应从 JWT Token 获取)
	userIDStr := c.Query("userId")
	var userID uint
	if userIDStr != "" {
		id, err := strconv.ParseUint(userIDStr, 10, 32)
		if err == nil {
			userID = uint(id)
		}
	}
	
	// 3. 创建 Client 对象
	client := &Client{Hub: hub, ID: userID, Conn: conn, Send: make(chan []byte, 256)}
	
	// 4. 注册到 Hub
	client.Hub.Register <- client

	// 5. 启动读写协程
	// Go 关键字：异步启动 Goroutines
	go client.WritePump()
	go client.ReadPump()
}
