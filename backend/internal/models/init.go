package models

import (
	"im-chat/internal/config"
	"log"

	"gorm.io/driver/mysql"
	"gorm.io/gorm"
)

// DB 全局数据库连接对象
// 类似于 Java 中的 EntityManager 或 JdbcTemplate
var DB *gorm.DB

// InitDB 初始化数据库连接
func InitDB() {
	var err error
	dsn := config.Global.MySQL.DSN

	// gorm.Open 建立数据库连接
	// &gorm.Config{} 可以配置日志、事务等行为
	DB, err = gorm.Open(mysql.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}

	// AutoMigrate 自动迁移模式
	// GORM 会自动创建或更新表结构以匹配 struct 定义
	// 类似于 Hibernate 的 hbm2ddl.auto = update
	DB.AutoMigrate(&User{}, &Message{})
}
