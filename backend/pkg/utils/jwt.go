package utils

import (
	"errors"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

// secretKey JWT 签名密钥
var secretKey = []byte("change-me-in-config")

// tokenTTL JWT 过期时长
var tokenTTL = 24 * time.Hour

// ConfigureJWT 配置 JWT 参数（启动时调用）
func ConfigureJWT(secret string, expireHours int) {
	if secret != "" {
		secretKey = []byte(secret)
	}

	if expireHours > 0 {
		tokenTTL = time.Duration(expireHours) * time.Hour
	}
}

// Claims 自定义 JWT 载荷结构体
// 继承了 standard claims (exp, iat 等) 并添加了 UserID
type Claims struct {
	UserID uint
	jwt.RegisteredClaims
}

// GenerateToken 生成 JWT Token
// userID: 用户唯一标识
// 返回: signed token string
func GenerateToken(userID uint) (string, error) {
	claims := &Claims{
		UserID: userID,
		RegisteredClaims: jwt.RegisteredClaims{
			// 设置过期时间
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(tokenTTL)),
			// 设置签发时间
			IssuedAt: jwt.NewNumericDate(time.Now()),
		},
	}

	// 使用 HS256 算法进行签名
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(secretKey)
}

// ParseToken 解析并验证 JWT Token
func ParseToken(tokenString string) (*Claims, error) {
	// ParseWithClaims 会自动验证签名和过期时间
	token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (interface{}, error) {
		return secretKey, nil
	})

	if err != nil {
		return nil, err
	}

	// 类型断言，获取自定义的 Claims 结构
	if claims, ok := token.Claims.(*Claims); ok && token.Valid {
		return claims, nil
	}

	return nil, errors.New("invalid token")
}
