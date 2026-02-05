# IM-Chat 项目文档

一个基于 **Go (后端)** 和 **SwiftUI (iOS 前端)** 构建的高性能即时通讯 (IM) 应用。本项目注重极致的 UI/UX 体验，采用了现代化的“液态玻璃 (Liquid Glass)”设计风格。

---

## 🛠 技术栈 (Tech Stack)

### 🖥 后端 (Backend)

- **语言**: Go (Golang)
- **架构**: 标准 Go 项目布局 (`Standard Go Project Layout`)
  - `cmd/`: 应用程序入口
  - `internal/`: 私有应用代码（业务逻辑）
  - `pkg/`: 可被外部导入的公共库代码
- **配置**: YAML (`config.yaml`)

### 📱 前端 (Frontend)

- **平台**: iOS (iPhone/iPad)
- **框架**: SwiftUI
- **图片加载**: Kingfisher
- **设计风格**:
  - **Dark Mode First**: 优先适配深色模式。
  - **Liquid Glass**: 广泛使用 `.ultraThinMaterial` 和高斯模糊，打造通透的高级感。
  - **Native Components**: 尽可能使用苹果原生组件 (Toolbar, TabView) 以保证最佳性能和交互体验。

---

## 📂 目录结构 (Directory Structure)

```text
IM-Chat/
├── backend/                # Go 后端代码
│   ├── cmd/                # 主程序入口
│   ├── internal/           # 核心业务逻辑 (API, Services, Models)
│   ├── pkg/                # 公共工具包
│   ├── config.yaml         # 后端配置文件
│   └── go.mod              # Go 依赖管理
│
├── IMChat/                 # iOS 前端工程
│   ├── IMChat/             # SwiftUI 源代码
│   │   ├── Views/          # UI 视图 (ProfileView, MainTabView 等)
│   │   ├── ViewModels/     # 视图模型 (AuthViewModel 等)
│   │   └── Models/         # 数据模型
│   └── IMChat.xcodeproj    # Xcode 项目文件
│
└── Agent.md                # 开发规范与 AI 助手指令
```

---

## 🚀 快速开始 (Getting Started)

### 后端启动

1.  进入后端目录：
    ```bash
    cd backend
    ```
2.  下载依赖：
    ```bash
    go mod tidy
    ```
3.  运行服务器：
    ```bash
    go run cmd/main.go
    # 或根据具体入口文件调整
    ```

### 前端运行

1.  确保已安装 **Xcode 15+**。
2.  双击打开 `IMChat/IMChat.xcodeproj`。
3.  等待 Swift Package Dependencies (如 Kingfisher) 下载完成。
4.  选择模拟器 (推荐 iPhone 15 Pro Max) 或真机。
5.  点击 **Run (Cmd+R)**。


---

## 📝 开发规范

- 遵循 `Agent.md` 中的定义。
- 代码注释需详细且使用中文。
- UI 修改需注意真机与预览的差异，优先保证真机效果。
