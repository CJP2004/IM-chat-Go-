package ws

// WsMessage WebSocket 消息结构体
// 定义了前后端通信的数据格式 (JSON)
type WsMessage struct {
	SenderID   uint   `json:"senderId"`   // 发送者 ID
	ReceiverID uint   `json:"receiverId"` // 接收者 ID (0 表示广播/群聊)
	Content    string `json:"content"`    // 消息内容
	Type       string `json:"type"`       // 消息类型: text, image, etc.
	MediaURL   string `json:"mediaUrl"`   // 媒体文件地址 (可选)
}
