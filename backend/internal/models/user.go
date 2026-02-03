package models

import (
	"gorm.io/gorm"
)

// User 用户模型
// 类似于 Java 中的 @Entity 类 (如 Hibernate/JPA 实体)
type User struct {
	// gorm.Model 包含了 ID, CreatedAt, UpdatedAt, DeletedAt 字段
	// 类似于 Java @MappedSuperclass 中的通用字段
	gorm.Model

	// `gorm:"..."` 是 struct tag，用于定义数据库列属性
	// uniqueIndex;not null 类似于 @Column(unique = true, nullable = false)
	Username string `gorm:"uniqueIndex;not null;size:191"`
	Password string `gorm:"not null"`
	Avatar   string
	Tagline  string `gorm:"default:'Online'"`
}

// FindUserByUsername 根据用户名查找用户
// 类似于 Repository 层的方法 (UserDao.findByUsername)
func FindUserByUsername(username string) (*User, error) {
	var user User
	// DB.Where(...) 类似于 Hibernate Criteria 或 SQL 拼接
	// First(&user) 将结果映射到 user 结构体中
	result := DB.Where("username = ?", username).First(&user)
	return &user, result.Error
}

// CreateUser 创建新用户
// 类似于 userRepository.save(user)
func CreateUser(user *User) error {
	return DB.Create(user).Error
}

// UpdateUser 更新用户信息
func UpdateUser(user *User) error {
	return DB.Save(user).Error
}

// FindUserByID 根据ID查找用户
func FindUserByID(id uint) (*User, error) {
	var user User
	result := DB.First(&user, id)
	return &user, result.Error
}
