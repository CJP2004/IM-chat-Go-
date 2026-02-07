package handlers

import (
	"im-chat/internal/middleware"
	"im-chat/internal/service"
	"im-chat/pkg/response"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
)

// messageService 消息服务实例
var messageService = new(service.MessageService)

// GetHistory 获取历史消息
// GET /api/messages?receiverId=2&page=1&pageSize=30
func GetHistory(c *gin.Context) {
	currentUserID, ok := middleware.CurrentUserID(c)
	if !ok {
		response.ErrorWithCode(c, http.StatusUnauthorized, response.CodeUnauthorized, "unauthorized")
		return
	}

	// 获取参数（senderId 从 token 获取，不再信任 query）
	receiverIDStr := c.Query("receiverId")
	pageStr := c.DefaultQuery("page", "1")
	pageSizeStr := c.DefaultQuery("pageSize", "30")

	// 参数校验
	if receiverIDStr == "" {
		response.Error(c, http.StatusBadRequest, "receiverId 为必填参数")
		return
	}

	receiverID, err := strconv.ParseUint(receiverIDStr, 10, 32)
	if err != nil {
		response.Error(c, http.StatusBadRequest, "receiverId 格式错误")
		return
	}

	page, err := strconv.Atoi(pageStr)
	if err != nil || page < 1 {
		response.Error(c, http.StatusBadRequest, "page 必须是大于等于 1 的整数")
		return
	}

	pageSize, err := strconv.Atoi(pageSizeStr)
	if err != nil || pageSize < 1 || pageSize > 100 {
		response.Error(c, http.StatusBadRequest, "pageSize 必须在 1-100 之间")
		return
	}

	// 调用 Service 层获取消息
	messages, err := messageService.GetHistory(currentUserID, uint(receiverID), page, pageSize)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "获取消息失败")
		return
	}

	// 返回成功响应
	response.Success(c, messages)
}
