package config

import (
	"errors"
	"log"
	"strings"

	"github.com/joho/godotenv"
	"github.com/spf13/viper"
)

// Config 全局配置结构体
// 对应 config.yaml 文件中的结构
// 类似于 Java 中的 Configuration Properties 类
type Config struct {
	Server ServerConfig `mapstructure:"server"`
	MySQL  MySQLConfig  `mapstructure:"mysql"`
	Redis  RedisConfig  `mapstructure:"redis"`
	COS    COSConfig    `mapstructure:"cos"`
	JWT    JWTConfig    `mapstructure:"jwt"`
}

type ServerConfig struct {
	Port string `mapstructure:"port"`
}

type MySQLConfig struct {
	DSN string `mapstructure:"dsn"` // Data Source Name (数据库连接字符串)
}

type RedisConfig struct {
	Addr     string `mapstructure:"addr"`
	Password string `mapstructure:"password"`
	DB       int    `mapstructure:"db"`
}

type COSConfig struct {
	SecretID  string `mapstructure:"secret_id"`
	SecretKey string `mapstructure:"secret_key"`
	Bucket    string `mapstructure:"bucket"`
	Region    string `mapstructure:"region"`
}

type JWTConfig struct {
	Secret      string `mapstructure:"secret"`
	ExpireHours int    `mapstructure:"expire_hours"`
}

// Global 全局配置变量，其他包可以直接访问 config.Global 获取配置
var Global Config

// Init 初始化配置
// 使用 Viper 库加载配置文件
// Viper 是 Go 中最流行的配置管理库，类似于 Spring Cloud Config 或 application.properties 加载器
func Init() {
	// 先尝试加载 .env（不存在时忽略）
	if err := godotenv.Load(".env"); err != nil {
		log.Printf("No .env file loaded: %v", err)
	}

	viper.SetConfigName("config") // 配置文件名称 (不带扩展名)
	viper.SetConfigType("yaml")   // 配置文件类型
	viper.AddConfigPath(".")      // 查找配置文件的路径 (当前目录)
	viper.SetEnvKeyReplacer(strings.NewReplacer(".", "_"))
	viper.AutomaticEnv()

	// 默认值（可被 config.yaml 或环境变量覆盖）
	viper.SetDefault("server.port", "2222")
	viper.SetDefault("jwt.expire_hours", 24)

	// 读取配置文件
	if err := viper.ReadInConfig(); err != nil {
		var notFound viper.ConfigFileNotFoundError
		if !errors.As(err, &notFound) {
			log.Fatalf("Error reading config file: %v", err)
		}
		log.Println("config.yaml not found, using environment/default values")
	}

	// 将读取到的配置反序列化到 Global 结构体中
	if err := viper.Unmarshal(&Global); err != nil {
		log.Fatalf("Unable to decode into struct, %v", err)
	}

	if Global.JWT.Secret == "" {
		log.Fatal("JWT secret is empty, please configure jwt.secret or JWT_SECRET")
	}
}
