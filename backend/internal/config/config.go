package config

import (
	"log"

	"github.com/spf13/viper"
)

// Config 全局配置结构体
// 对应 config.yaml 文件中的结构
// 类似于 Java 中的 Configuration Properties 类
type Config struct {
	MySQL MySQLConfig
	Redis RedisConfig
	COS   COSConfig
}

type MySQLConfig struct {
	DSN string // Data Source Name (数据库连接字符串)
}

type RedisConfig struct {
	Addr     string
	Password string
	DB       int
}

type COSConfig struct {
	SecretID  string `mapstructure:"secret_id"`
	SecretKey string `mapstructure:"secret_key"`
	Bucket    string `mapstructure:"bucket"`
	Region    string `mapstructure:"region"`
}

// Global 全局配置变量，其他包可以直接访问 config.Global 获取配置
var Global Config

// Init 初始化配置
// 使用 Viper 库加载配置文件
// Viper 是 Go 中最流行的配置管理库，类似于 Spring Cloud Config 或 application.properties 加载器
func Init() {
	viper.SetConfigName("config") // 配置文件名称 (不带扩展名)
	viper.SetConfigType("yaml")   // 配置文件类型
	viper.AddConfigPath(".")      // 查找配置文件的路径 (当前目录)

	// 读取配置文件
	if err := viper.ReadInConfig(); err != nil {
		log.Fatalf("Error reading config file, %s", err)
	}

	// 将读取到的配置反序列化到 Global 结构体中
	if err := viper.Unmarshal(&Global); err != nil {
		log.Fatalf("Unable to decode into struct, %v", err)
	}
}
