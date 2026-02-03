# 💬 IM-Chat-Go

> 一个基于 Go (Gin) + Vue 3 的高性能即时通讯系统。
> A High-performance Instant Messaging System built with Go and Vue 3.

![Go](https://img.shields.io/badge/Go-1.21+-00ADD8?style=flat&logo=go)
![Gin](https://img.shields.io/badge/Web_Framework-Gin-00ADD8?style=flat&logo=go)
![Vue](https://img.shields.io/badge/Frontend-Vue.js_3-4FC08D?style=flat&logo=vue.js)
![MySQL](https://img.shields.io/badge/Database-MySQL_8.0-4479A1?style=flat&logo=mysql)
![License](https://img.shields.io/badge/License-MIT-blue.svg)

## 📖 项目简介 (Introduction)

本项目是一个前后端分离的即时通讯（IM）系统。作为从 Java 转 Go 的实战项目，它采用了经典的 Go Web 开发模式，旨在探索 Go 语言在高并发网络编程、WebSocket 长连接以及云原生架构方向的应用潜力。

前端采用 Vue 3 + Vite 构建，界面现代化且响应迅速。

## ✨ 核心功能 (Features)

- **🔐 用户体系**：注册、登录、JWT 鉴权、个人信息管理（头像/签名修改）。
- **💬 实时通讯**：基于 WebSocket 实现低延迟的一对一聊天。
- **📂 消息记录**：支持历史消息漫游（存储于 MySQL）。
- **🖼️ 多媒体支持**：支持图片上传与发送。
- **🛡️ 基础安全**：CORS 跨域配置、密码加密存储、优雅的错误恢复（Recovery）。

## 🛠️ 技术栈 (Tech Stack)

### Backend (Go)
- **Web Framework**: [Gin](https://github.com/gin-gonic/gin) - 高性能 HTTP Web 框架
- **ORM**: [GORM](https://gorm.io/) - 开发者友好的 ORM 库
- **Database**: MySQL 8.0
- **Real-time**: Gorilla WebSocket / Native Net Library
- **Config**: Viper (Planned)
- **Utils**: JWT-Go (Authentication)

### Frontend (Vue)
- **Framework**: Vue 3 (Composition API)
- **Build Tool**: Vite
- **UI Component**: TailwindCSS / Custom CSS
- **State Management**: Pinia

## 🚀 快速开始 (Getting Started)

### 环境要求 (Prerequisites)
- Go 1.20+
- Node.js 16+
- MySQL 8.0+


```bash
# 1. 克隆项目
git clone [https://github.com/CJP2004/IM-chat-Go.git](https://github.com/CJP2004/IM-chat-Go.git)

# 2. 安装 Go 依赖
go mod tidy

# 3. 配置数据库
# 请在 config/config.yaml 或代码中修改你的 MySQL 连接串等
# dsn := "user:password@tcp(127.0.0.1:3306)/im_chat?charset=utf8mb4&parseTime=True&loc=Local"

# 4. 运行后端服务
go run main.go

# 5. 安装前端依赖
npm install

# 6. 启动前端开发服务器
npm run dev
