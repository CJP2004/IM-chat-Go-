# Daily Work Report (IM-Chat)

时间范围：过去 24 小时（截至 2026-02-04）

### 1. Initial commit
* **🛠 具体实现逻辑**:
  * 建立完整前后端项目骨架：后端采用 Gin + GORM + WebSocket Hub 的分层结构（Handler/Service/Model + Router），前端用 Vue 3 + Vite + Pinia + Tailwind 完成基础聊天界面与鉴权流程。
  * 后端提供用户、消息、上传等基础接口与 WebSocket 长连接能力，并配套通用响应、JWT/密码加密、上传工具与配置加载入口。
* **💻 关键代码变动**:
  * 后端入口与路由组装：`backend/cmd/server/main.go`、`backend/internal/router/router.go`。
  * WebSocket 核心：`backend/internal/ws/client.go`、`backend/internal/ws/hub.go`、`backend/internal/ws/message.go`。
  * 业务分层：`backend/internal/handlers/*`、`backend/internal/service/*`、`backend/internal/models/*`。
  * 前端基础聊天与设置面板：`frontend/src/components/chat/*`、`frontend/src/stores/*`、`frontend/src/views/*`。
* **💡 改进点**:
  * 一次性搭好分层与通信基础设施，后续功能只需在 Service/Handler 或前端组件中按职责扩展，降低迭代成本。

### 2. Create README.md
* **🛠 具体实现逻辑**:
  * 补全项目介绍、核心功能、技术栈与快速启动步骤，形成可复用的入门说明。
* **💻 关键代码变动**:
  * 文档新增：`README.md`（项目简介、功能清单、依赖与启动流程）。
* **💡 改进点**:
  * 统一对外说明与环境准备标准，降低新成员或使用者的上手成本。

### 3. 获取用户设备，支持长段文字的发送，已读未读状态，前端优化
* **🛠 具体实现逻辑**:
  * WebSocket 层扩大 `maxMessageSize` 支持长文本消息。
  * 解析 User-Agent 并写入用户 Tagline，建立设备信息记录能力。
  * 引入“已读回执”消息类型：后端在 Hub 内区分 `read_ack` 与普通消息，回执触发已读标记；前端在消息模型中增加 `isRead` 并展示已读/送达状态。
  * 前端输入框支持自适应高度与 Shift+Enter 换行，消息列表按发送者分组显示，头像/气泡间距优化。
* **💻 关键代码变动**:
  * 长文本支持：`backend/internal/ws/client.go`（`maxMessageSize` 从 512 调整至 65536）。
  * 设备解析工具：`backend/pkg/utils/device.go`，并在 `backend/internal/ws/client.go` 中写入用户 Tagline。
  * 已读逻辑：`backend/internal/ws/hub.go`（处理 `read_ack`）、`frontend/src/stores/chat.ts`（`isRead` 字段与回执处理）、`frontend/src/components/chat/MessageList.vue`/`MessageBubble.vue`（状态展示与分组）。
  * 输入体验：`frontend/src/components/chat/ChatInput.vue`（自适应高度、Shift+Enter 换行）。
* **💡 改进点**:
  * 提升长文本与多轮对话体验，已读回执让消息状态更明确；设备信息可用于后续的在线状态或多端识别。

### 4. 新增多张图片的叠放，上传预览图/进度条
* **🛠 具体实现逻辑**:
  * 新增 `ImageStack` 组件，使用 `motion-v` 实现卡片式叠放与拖拽动效；连续图片按发送者合并展示为堆叠卡片。
  * 上传流程加入本地预览与进度展示：上传开始后显示预览图与进度条，完成后短暂保留 100% 状态再复位。
  * 图片查看体验强化：单图与堆叠图均支持 Lightbox 全屏查看。
* **💻 关键代码变动**:
  * 依赖新增：`frontend/package.json`（引入 `motion-v`）。
  * 组件新增：`frontend/src/components/chat/ImageStack.vue`。
  * 预览与进度：`frontend/src/components/chat/ChatInput.vue`、`frontend/src/stores/chat.ts`（`uploadProgress`、`isUploading` 与 `onUploadProgress`）。
  * 叠放/灯箱逻辑：`frontend/src/components/chat/MessageList.vue`、`frontend/src/components/chat/MessageBubble.vue`。
* **💡 改进点**:
  * 多图消息更紧凑且可交互，上传过程有明确反馈；灯箱查看避免图片在气泡内受限，提高可用性。

