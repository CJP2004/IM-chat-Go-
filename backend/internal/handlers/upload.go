package handlers

import (
	"im-chat/pkg/response"
	"im-chat/pkg/utils"
	"net/http"

	"github.com/gin-gonic/gin"
)

// Upload 处理文件上传
func Upload(c *gin.Context) {
	// 1. 获取上传的文件
	file, header, err := c.Request.FormFile("file")
	if err != nil {
		response.Error(c, http.StatusBadRequest, "File is required")
		return
	}
	defer file.Close()

	// 2. 上传到 COS
	url, err := utils.UploadFile(file, header)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "Failed to upload file")
		return
	}

	// 3. 返回 URL
	c.JSON(http.StatusOK, gin.H{"url": url})
}
