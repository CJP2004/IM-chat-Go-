package service

import (
	"im-chat/internal/models"
)

// MessageService 消息相关的业务逻辑
// 职责：封装消息的创建、查询等操作，为 Handler 和 WebSocket 提供统一接口
type MessageService struct{}

// SaveMessage 保存消息到数据库
// 参数：发送者ID、接收者ID、消息内容、消息类型、媒体URL
// 返回：保存后的消息对象（包含ID和时间戳）
func (s *MessageService) SaveMessage(senderID, receiverID uint, content, msgType, mediaURL string) (*models.Message, error) {
	// 构建消息对象
	msg := &models.Message{
		SenderID:   senderID,
		ReceiverID: receiverID,
		Content:    content,
		Type:       msgType,
		MediaURL:   mediaURL,
		IsRead:     false,
	}

	// 调用 Model 层保存
	if err := models.CreateMessage(msg); err != nil {
		return nil, err
	}

	return msg, nil
}

// GetHistory 获取两个用户之间的历史消息
// 以“最新页优先”分页，返回结果按时间正序（便于前端直接渲染）
func (s *MessageService) GetHistory(user1ID, user2ID uint, page, pageSize int) ([]models.Message, error) {
	return models.GetMessagesPage(user1ID, user2ID, page, pageSize)
}

// GetLastMessage 获取两个用户之间最近的一条消息
// 用于会话列表显示预览
func (s *MessageService) GetLastMessage(user1ID, user2ID uint) (*models.Message, error) {
	return models.GetLastMessage(user1ID, user2ID)
}

// MarkMessagesRead UpdateReadStatus 更新消息已读状态
// 将指定接收者、指定发送者的所有未读消息标记为已读（简单起见，暂不按 MessageID 逐条更，而是会话维度）
// 或者根据前端传来的 messageId 列表更新
// 这里暂时实现：把 user1 发给 user2 的所有消息标记为已读
func (s *MessageService) MarkMessagesRead(senderID, receiverID uint) error {
	return models.DB.Model(&models.Message{}).
		Where("sender_id = ? AND receiver_id = ? AND is_read = ?", senderID, receiverID, false).
		Update("is_read", true).Error
}
