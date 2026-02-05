package handlers

import (
	"im-chat/internal/models"
	"im-chat/internal/service"
	"im-chat/pkg/response"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
)

// msgService 消息服务实例（用于获取最近消息）
var msgService = new(service.MessageService)

// ListUsers 获取用户列表接口
// 返回除当前用户外的所有用户（类似于通讯录）
// GET /api/users?userId=1
func ListUsers(c *gin.Context) {
	// 获取当前用户ID
	currentUserIDStr := c.Query("userId")
	var currentUserID uint
	if currentUserIDStr != "" {
		if id, err := strconv.Atoi(currentUserIDStr); err == nil {
			currentUserID = uint(id)
		}
	}

	var users []models.User

	// 查询数据库所有用户
	if err := models.DB.Find(&users).Error; err != nil {
		response.Error(c, http.StatusInternalServerError, "获取用户列表失败")
		return
	}

	// 构建响应数据（过滤敏感信息如密码）
	var result []gin.H
	for _, u := range users {
		// 跳过当前登录用户
		if u.ID == currentUserID {
			continue
		}

		lastMsgContent := "Click to chat..."
		lastMsgTime := ""

		// 获取与该用户的最近一条消息
		if currentUserID != 0 {
			msg, err := msgService.GetLastMessage(currentUserID, u.ID)
			if err == nil && msg.ID != 0 {
				if msg.Type == "image" {
					lastMsgContent = "[图片]"
				} else {
					lastMsgContent = msg.Content
				}
				lastMsgTime = msg.CreatedAt.Format("2006-01-02 15:04:05")
			}
		}

		result = append(result, gin.H{
			"id":              u.ID,
			"username":        u.Username,
			"avatar":          u.Avatar,
			"tagline":         u.Tagline,
			"lastMessage":     lastMsgContent,
			"lastMessageTime": lastMsgTime,
		})
	}

	response.Success(c, result)
}
