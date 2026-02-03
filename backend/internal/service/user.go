package service

import (
	"errors"
	"im-chat/internal/models"
	"im-chat/pkg/utils"
)

// UserService 定义用户相关的业务逻辑
// 类似于 Java 中的 UserService
type UserService struct{}

// Register 用户注册业务
// 负责：检查用户是否存在 -> 加密密码 -> 创建用户
func (s *UserService) Register(username, password string) error {
	// 1. 检查用户名是否存在 (调用 DAO/Model 层)
	_, err := models.FindUserByUsername(username)
	if err == nil {
		return errors.New("username already exists")
	}

	// 2. 密码加密 (业务逻辑)
	hashedPassword, err := utils.HashPassword(password)
	if err != nil {
		return err
	}

	// 3. 构建用户对象并保存
	user := models.User{
		Username: username,
		Password: hashedPassword,
		Avatar:   "https://api.dicebear.com/7.x/avataaars/svg?seed=" + username,
	}

	return models.CreateUser(&user)
}

// Login 用户登录业务
// 负责：查找用户 -> 校验密码 -> 生成 Token
// 返回: token, user, error
func (s *UserService) Login(username, password string) (string, *models.User, error) {
	// 1. 查找用户
	user, err := models.FindUserByUsername(username)
	if err != nil {
		return "", nil, errors.New("invalid username or password")
	}

	// 2. 校验密码
	if !utils.CheckPasswordHash(password, user.Password) {
		return "", nil, errors.New("invalid username or password")
	}

	// 3. 生成 Token
	token, err := utils.GenerateToken(user.ID)
	if err != nil {
		return "", nil, err
	}

	return token, user, nil
}
