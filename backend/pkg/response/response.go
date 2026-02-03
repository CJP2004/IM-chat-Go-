package response

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// Response 统一响应结构体
// 类似于 Java 中的 Result<T> 或 ApiResponse
type Response struct {
	Code int         `json:"code"` // 业务状态码 (200: 成功, 其他: 失败)
	Msg  string      `json:"msg"`  // 提示信息
	Data interface{} `json:"data"` // 数据载荷
}

// Success 成功响应
func Success(c *gin.Context, data interface{}) {
	c.JSON(http.StatusOK, Response{
		Code: 200,
		Msg:  "success",
		Data: data,
	})
}

// Error 错误响应
func Error(c *gin.Context, httpStatus int, msg string) {
	c.JSON(httpStatus, Response{
		Code: httpStatus, // 或自定义业务错误码
		Msg:  msg,
		Data: nil,
	})
}
