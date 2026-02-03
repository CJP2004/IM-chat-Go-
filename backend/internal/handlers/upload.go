package handlers

import (
	"im-chat/pkg/utils"
	"net/http"

	"github.com/gin-gonic/gin"
)

// Upload 处理文件上传
func Upload(c *gin.Context) {
	// 1. 获取上传的文件
	file, header, err := c.Request.FormFile("file")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "File is required"})
		return
	}
	defer file.Close()

	// 2. 上传到 COS
	url, err := utils.UploadFile(file, header)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to upload file"})
		return
	}

	// 3. 返回 URL
	c.JSON(http.StatusOK, gin.H{"url": url})
}
