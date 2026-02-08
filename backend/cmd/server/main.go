package main

import (
	"fmt"
	"log"

	"im-chat/internal/config"
	"im-chat/internal/models"
	"im-chat/internal/router" // Import router
	"im-chat/internal/ws"
	"im-chat/pkg/utils"
)

func main() {
	// 1. 初始化配置
	config.Init()
	utils.ConfigureJWT(config.Global.JWT.Secret, config.Global.JWT.ExpireHours)

	// 2. 初始化数据库
	models.InitDB()

	// 3. 初始化 WebSocket Hub
	hub := ws.NewHub()
	go hub.Run()

	// 4. 初始化路由 (从 main.go 抽离)
	// 现在的 main 函数非常清爽，只负责组装和启动
	r := router.SetupRouter(hub)

	port := config.Global.Server.Port
	fmt.Printf("Server starting on :%s\n", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatalf("Server failed to start: %v", err)
	}
}
