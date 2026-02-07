package handlers

import (
	"im-chat/internal/middleware"
	"im-chat/internal/models" // Import models
	"im-chat/internal/service"
	"im-chat/pkg/response" // Import response package
	"im-chat/pkg/utils"    // Import utils for device parsing
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
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
		if strings.Contains(err.Error(), "already exists") {
			response.ErrorWithCode(c, http.StatusConflict, response.CodeConflict, err.Error())
			return
		}
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
	models.DB.Save(user)

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
	models.DB.Save(user)

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
	userID, ok := middleware.CurrentUserID(c)
	if !ok {
		response.ErrorWithCode(c, http.StatusUnauthorized, response.CodeUnauthorized, "unauthorized")
		return
	}

	var input struct {
		Avatar string `json:"avatar" binding:"required"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		response.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	user, err := models.FindUserByID(userID)
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			response.Error(c, http.StatusNotFound, "User not found")
			return
		}
		response.Error(c, http.StatusInternalServerError, "Failed to load user")
		return
	}

	user.Avatar = input.Avatar
	if err := models.UpdateUser(user); err != nil {
		response.Error(c, http.StatusInternalServerError, "Failed to update avatar")
		return
	}

	response.Success(c, gin.H{"avatar": user.Avatar})
}

// UpdateTagline 更新个性签名
func UpdateTagline(c *gin.Context) {
	userID, ok := middleware.CurrentUserID(c)
	if !ok {
		response.ErrorWithCode(c, http.StatusUnauthorized, response.CodeUnauthorized, "unauthorized")
		return
	}

	var input struct {
		Tagline string `json:"tagline"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		response.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	user, err := models.FindUserByID(userID)
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			response.Error(c, http.StatusNotFound, "User not found")
			return
		}
		response.Error(c, http.StatusInternalServerError, "Failed to load user")
		return
	}

	user.Tagline = input.Tagline
	if err := models.UpdateUser(user); err != nil {
		response.Error(c, http.StatusInternalServerError, "Failed to update tagline")
		return
	}

	response.Success(c, gin.H{"tagline": user.Tagline})
}
