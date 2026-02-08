package middleware

import (
	"net/http"
	"strings"

	"im-chat/pkg/response"
	"im-chat/pkg/utils"

	"github.com/gin-gonic/gin"
)

const contextUserIDKey = "userID"

// HTTPAuth 校验 Authorization: Bearer <token> 并把 userID 注入 context
func HTTPAuth() gin.HandlerFunc {
	return func(c *gin.Context) {
		token := extractBearerToken(c.GetHeader("Authorization"))
		if token == "" {
			response.ErrorWithCode(c, http.StatusUnauthorized, response.CodeUnauthorized, "missing or invalid authorization token")
			c.Abort()
			return
		}

		claims, err := utils.ParseToken(token)
		if err != nil {
			response.ErrorWithCode(c, http.StatusUnauthorized, response.CodeUnauthorized, "invalid or expired token")
			c.Abort()
			return
		}

		c.Set(contextUserIDKey, claims.UserID)
		c.Next()
	}
}

// CurrentUserID 从 gin context 读取当前用户 ID
func CurrentUserID(c *gin.Context) (uint, bool) {
	raw, ok := c.Get(contextUserIDKey)
	if !ok {
		return 0, false
	}

	userID, ok := raw.(uint)
	return userID, ok
}

func extractBearerToken(header string) string {
	if header == "" {
		return ""
	}

	parts := strings.SplitN(header, " ", 2)
	if len(parts) != 2 {
		return ""
	}
	if !strings.EqualFold(parts[0], "Bearer") {
		return ""
	}

	token := strings.TrimSpace(parts[1])
	if token == "" {
		return ""
	}

	return token
}
