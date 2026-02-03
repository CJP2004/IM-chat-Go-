package utils

import (
	"context"
	"fmt"
	"im-chat/internal/config"
	"mime/multipart"
	"net/http"
	"net/url"
	"path/filepath"
	"time"

	"github.com/tencentyun/cos-go-sdk-v5"
)

// UploadFile 上传文件到腾讯云 COS
func UploadFile(file multipart.File, header *multipart.FileHeader) (string, error) {
	// 1. 初始化 COS Client
	u, _ := url.Parse(fmt.Sprintf("https://%s.cos.%s.myqcloud.com", config.Global.COS.Bucket, config.Global.COS.Region))
	b := &cos.BaseURL{BucketURL: u}
	client := cos.NewClient(b, &http.Client{
		Transport: &cos.AuthorizationTransport{
			SecretID:  config.Global.COS.SecretID,
			SecretKey: config.Global.COS.SecretKey,
		},
	})

	// 2. 生成唯一文件名 (uuid 或 时间戳)
	ext := filepath.Ext(header.Filename)
	filename := fmt.Sprintf("uploads/%d%s", time.Now().UnixNano(), ext)

	// 3. 上传
	_, err := client.Object.Put(context.Background(), filename, file, nil)
	if err != nil {
		return "", err
	}

	// 4. 返回访问 URL
	return fmt.Sprintf("https://%s.cos.%s.myqcloud.com/%s", config.Global.COS.Bucket, config.Global.COS.Region, filename), nil
}
