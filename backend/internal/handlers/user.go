package handlers

import (
	"im-chat/internal/models" // Import models
	"im-chat/internal/service"
	"im-chat/pkg/response" // Import response package
	"im-chat/pkg/utils"    // Import utils for device parsing
	"net/http"

	"github.com/gin-gonic/gin"
)

// userService 实例
var userService = new(service.UserService)

// Register 处理用户注册请求
func Register(c *gin.Context) {
	var input struct {
		Username string `json:"username" binding:"required"`
		Password string `json:"password" binding:"required"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		response.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	// 调用 Service 层注册
	err := userService.Register(input.Username, input.Password)
	if err != nil {
		response.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	// 注册成功后自动登录
	token, user, err := userService.Login(input.Username, input.Password)
	if err != nil {
		response.Error(c, http.StatusUnauthorized, err.Error())
		return
	}

    // 解析设备信息并更新 Tagline
	uaString := c.GetHeader("User-Agent")
	deviceName := utils.ParseDevice(uaString)
	user.Tagline = deviceName
	models.DB.Save(&user)

	response.Success(c, gin.H{
		"token": token,
		"user": gin.H{
			"id":       user.ID,
			"username": user.Username,
			"avatar":   user.Avatar,
			"tagline":  user.Tagline,
		},
	})
}

// Login 处理用户登录请求
func Login(c *gin.Context) {
	var input struct {
		Username string `json:"username" binding:"required"`
		Password string `json:"password" binding:"required"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		response.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	// 调用 Service 层
	token, user, err := userService.Login(input.Username, input.Password)
	if err != nil {
		response.Error(c, http.StatusUnauthorized, err.Error())
		return
	}

	// 解析设备信息并更新 Tagline
	uaString := c.GetHeader("User-Agent")
	deviceName := utils.ParseDevice(uaString)
	user.Tagline = deviceName
	models.DB.Save(&user)

	response.Success(c, gin.H{
		"token": token,
		"user": gin.H{
			"id":       user.ID,
			"username": user.Username,
			"avatar":   user.Avatar,
			"tagline":  user.Tagline,
		},
	})
}

// UpdateAvatar 更新头像
func UpdateAvatar(c *gin.Context) {
	// 简单实现：从 Query 获取 UserID (实际应该从 Token 获取)
	userIDStr := c.Query("userId")
	var input struct {
		Avatar string `json:"avatar" binding:"required"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		response.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	if userIDStr == "" {
		response.Error(c, http.StatusBadRequest, "User ID is required")
		return
	}

	// 这里直接调用 Model 层，实际项目建议走 Service 层
	// 为了简化流程，暂不修改 Service 接口
	var user models.User
	if err := models.DB.First(&user, userIDStr).Error; err != nil {
		response.Error(c, http.StatusNotFound, "User not found")
		return
	}

	user.Avatar = input.Avatar
	if err := models.UpdateUser(&user); err != nil {
		response.Error(c, http.StatusInternalServerError, "Failed to update avatar")
		return
	}

	response.Success(c, gin.H{"avatar": user.Avatar})
}

// UpdateTagline 更新个性签名
func UpdateTagline(c *gin.Context) {
	userIDStr := c.Query("userId")
	var input struct {
		Tagline string `json:"tagline"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		response.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	if userIDStr == "" {
		response.Error(c, http.StatusBadRequest, "User ID is required")
		return
	}

	var user models.User
	if err := models.DB.First(&user, userIDStr).Error; err != nil {
		response.Error(c, http.StatusNotFound, "User not found")
		return
	}

	user.Tagline = input.Tagline
	if err := models.UpdateUser(&user); err != nil {
		response.Error(c, http.StatusInternalServerError, "Failed to update tagline")
		return
	}

	response.Success(c, gin.H{"tagline": user.Tagline})
}
