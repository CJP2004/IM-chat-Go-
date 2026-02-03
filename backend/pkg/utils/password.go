package utils

import (
	"golang.org/x/crypto/bcrypt"
)

// HashPassword 使用 bcrypt 算法对密码进行哈希加密
// bcrypt 会自动处理盐值 (salt)，比简单的 MD5/SHA 安全得多
func HashPassword(password string) (string, error) {
	// Cost 14 是计算复杂度，越高越慢但越安全
	bytes, err := bcrypt.GenerateFromPassword([]byte(password), 14)
	return string(bytes), err
}

// CheckPasswordHash 验证密码是否正确
// password: 用户输入的明文密码
// hash: 数据库中存储的哈希值
func CheckPasswordHash(password, hash string) bool {
	err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(password))
	return err == nil
}
