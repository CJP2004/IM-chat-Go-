package handlers

import (
	"im-chat/internal/service"
	"im-chat/pkg/response"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
)

// messageService 消息服务实例
var messageService = new(service.MessageService)

// GetHistory 获取历史消息
// GET /api/messages?senderId=1&receiverId=2
func GetHistory(c *gin.Context) {
	// 获取参数
	senderIDStr := c.Query("senderId")
	receiverIDStr := c.Query("receiverId")

	// 参数校验
	if senderIDStr == "" || receiverIDStr == "" {
		response.Error(c, http.StatusBadRequest, "senderId 和 receiverId 为必填参数")
		return
	}

	// 转换类型
	senderID, err := strconv.ParseUint(senderIDStr, 10, 32)
	if err != nil {
		response.Error(c, http.StatusBadRequest, "senderId 格式错误")
		return
	}

	receiverID, err := strconv.ParseUint(receiverIDStr, 10, 32)
	if err != nil {
		response.Error(c, http.StatusBadRequest, "receiverId 格式错误")
		return
	}

	// 调用 Service 层获取消息
	messages, err := messageService.GetHistory(uint(senderID), uint(receiverID))
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "获取消息失败")
		return
	}

	// 返回成功响应
	response.Success(c, messages)
}
