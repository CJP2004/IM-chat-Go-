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

// GetMessagesPage 分页获取两个用户之间的历史消息
// 分页策略：page=1 返回最新一页；返回结果按 created_at 升序，便于前端直接渲染。
func GetMessagesPage(user1ID, user2ID uint, page, pageSize int) ([]Message, error) {
	if page < 1 {
		page = 1
	}
	if pageSize < 1 {
		pageSize = 30
	}

	offset := (page - 1) * pageSize
	var messages []Message

	err := DB.Where("(sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)",
		user1ID, user2ID, user2ID, user1ID).
		Order("created_at desc").
		Limit(pageSize).
		Offset(offset).
		Find(&messages).Error
	if err != nil {
		return nil, err
	}

	// 反转为时间正序，前端可直接 append/prepend
	for left, right := 0, len(messages)-1; left < right; left, right = left+1, right-1 {
		messages[left], messages[right] = messages[right], messages[left]
	}

	return messages, nil
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
