package router

import (
	"im-chat/internal/handlers"
	"im-chat/internal/middleware"
	"im-chat/internal/ws"
	"net/http"
	"os"
	"strings"

	"github.com/gin-gonic/gin"
)

// SetupRouter 初始化路由
// 将路由定义从 main.go 中抽离出来，类似于 Java 中的 Configuration 类或 RouteConfig
func SetupRouter(hub *ws.Hub) *gin.Engine {
	r := gin.Default()

	// CORS 中间件
	r.Use(corsMiddleware())

	// API 路由组
	api := r.Group("/api")
	{
		api.POST("/register", handlers.Register) //用户注册
		api.POST("/login", handlers.Login)       //用户登录

		authorized := api.Group("")
		authorized.Use(middleware.HTTPAuth())
		{
			authorized.GET("/users", handlers.ListUsers)            //获取用户列表
			authorized.POST("/upload", handlers.Upload)             // 上传文件
			authorized.GET("/messages", handlers.GetHistory)        // 获取历史消息
			authorized.PUT("/user/avatar", handlers.UpdateAvatar)   // 更新头像
			authorized.PUT("/user/tagline", handlers.UpdateTagline) // 更新签名
		}
	}

	// WebSocket 路由
	r.GET("/ws", middleware.HTTPAuth(), func(c *gin.Context) {
		ws.ServeWs(hub, c)
	})

	// 健康检查
	r.GET("/ping", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"message": "pong"})
	})

	return r
}

func corsMiddleware() gin.HandlerFunc {
	allowedOrigins := loadAllowedOrigins()

	return func(c *gin.Context) {
		origin := strings.TrimSpace(c.GetHeader("Origin"))
		if origin != "" {
			if _, ok := allowedOrigins[origin]; ok {
				c.Writer.Header().Set("Access-Control-Allow-Origin", origin)
				c.Writer.Header().Set("Vary", "Origin")
				c.Writer.Header().Set("Access-Control-Allow-Credentials", "true")
			} else if c.Request.Method == http.MethodOptions {
				c.AbortWithStatus(http.StatusForbidden)
				return
			}
		}

		c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization, accept, origin, Cache-Control, X-Requested-With")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS, GET, PUT")

		if c.Request.Method == http.MethodOptions {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}

		c.Next()
	}
}

func loadAllowedOrigins() map[string]struct{} {
	raw := strings.TrimSpace(os.Getenv("CORS_ALLOW_ORIGINS"))
	if raw == "" {
		raw = "http://localhost:5173,http://127.0.0.1:5173,http://localhost:3000,http://127.0.0.1:3000,http://localhost:8080,http://127.0.0.1:8080"
	}

	allowed := make(map[string]struct{})
	for _, item := range strings.Split(raw, ",") {
		origin := strings.TrimSpace(item)
		if origin == "" {
			continue
		}
		allowed[origin] = struct{}{}
	}
	return allowed
}
