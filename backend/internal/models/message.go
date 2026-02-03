package models

import (
	"gorm.io/gorm"
)

// Message 消息模型
// 存储历史聊天记录
type Message struct {
	gorm.Model

	SenderID   uint   `gorm:"index;not null"`         // 发送者 ID
	ReceiverID uint   `gorm:"index"`                  // 接收者 ID (0 表示广播)
	Content    string `gorm:"type:text"`              // 消息内容
	Type       string `gorm:"size:20;default:'text'"` // 消息类型: text, image
	MediaURL   string `gorm:"size:255"`               // 媒体文件地址 (如果是图片消息)
	IsRead     bool   `gorm:"default:false"`          // 是否已读
}

// CreateMessage 保存消息到数据库
func CreateMessage(msg *Message) error {
	return DB.Create(msg).Error
}

// GetMessages 获取两个用户之间的历史消息
func GetMessages(user1ID, user2ID uint) ([]Message, error) {
	var messages []Message
	// 查询 A 发给 B，或者 B 发给 A 的消息
	err := DB.Where("(sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)",
		user1ID, user2ID, user2ID, user1ID).
		Order("created_at asc"). // 按时间正序
		Find(&messages).Error
	return messages, err
}

// GetLastMessage 获取两个用户之间最近的一条消息
func GetLastMessage(user1ID, user2ID uint) (*Message, error) {
	var message Message
	err := DB.Where("(sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)",
		user1ID, user2ID, user2ID, user1ID).
		Order("created_at desc"). // 按时间倒序
		First(&message).Error
	return &message, err
}
