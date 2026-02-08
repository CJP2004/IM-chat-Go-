package response

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

const (
	CodeSuccess      = 200
	CodeBadRequest   = 40001
	CodeUnauthorized = 40101
	CodeForbidden    = 40301
	CodeNotFound     = 40401
	CodeConflict     = 40901
	CodeInternal     = 50001
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
		Code: CodeSuccess,
		Msg:  "success",
		Data: data,
	})
}

// Error 错误响应
func Error(c *gin.Context, httpStatus int, msg string) {
	ErrorWithCode(c, httpStatus, mapHTTPStatusToBizCode(httpStatus), msg)
}

// ErrorWithCode 错误响应（显式业务码）
func ErrorWithCode(c *gin.Context, httpStatus int, bizCode int, msg string) {
	c.JSON(httpStatus, Response{
		Code: bizCode,
		Msg:  msg,
		Data: nil,
	})
}

func mapHTTPStatusToBizCode(httpStatus int) int {
	switch httpStatus {
	case http.StatusBadRequest:
		return CodeBadRequest
	case http.StatusUnauthorized:
		return CodeUnauthorized
	case http.StatusForbidden:
		return CodeForbidden
	case http.StatusNotFound:
		return CodeNotFound
	case http.StatusConflict:
		return CodeConflict
	default:
		return CodeInternal
	}
}
