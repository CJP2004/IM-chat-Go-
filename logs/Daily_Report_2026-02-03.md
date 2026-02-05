# IM-Chat 深度技术日报（2026-02-03）

### 1. Initial commit
* **🛠 具体实现逻辑**:
  * 初始化后端 Go 项目结构，采用 `cmd/` 启动入口、`internal/` 分层（handlers/service/models/router/ws）与 `pkg/` 工具包，形成基础的请求处理与 WebSocket 通道。
  * 引入 Gin + GORM + Viper + JWT + WebSocket 依赖，建立配置加载、鉴权、数据库访问与实时通信骨架。
  * 前端采用 Vue3 + Vite + Pinia + Tailwind，搭建聊天主界面、登录/注册、侧边栏、消息列表/气泡、设置面板等组件，提供基础聊天 UI 与状态管理。
* **💻 关键代码变动**:
  * 后端：`backend/cmd/server/main.go` 组装启动流程；`backend/internal/router/router.go` 注册 API；`backend/internal/ws/*` 建立 Hub/Client 与消息分发；`backend/internal/models/*` 定义 User/Message；`backend/internal/service/*` 实现业务封装；`backend/pkg/utils/*` 提供 JWT/密码/上传工具。
  * 前端：`frontend/src/components/chat/*`（聊天头部/输入/消息列表/气泡）；`frontend/src/stores/*`（chat/user/settings/ui/toast）；`frontend/src/views/*`（Login/Register/Chat）。
* **💡 改进点**:
  * 一次性建立清晰的后端分层与前端组件/状态结构，后续功能迭代能直接落在明确位置，减少耦合与重复。

### 2. Create README.md
* **🛠 具体实现逻辑**:
  * 补充项目说明文档，明确项目目标、技术栈与基础使用方式，形成对外可读的入口说明。
* **💻 关键代码变动**:
  * `README.md` 新增 68 行内容，覆盖项目简介与基础指引。
* **💡 改进点**:
  * 降低新成员上手成本，减少口头/重复解释，提高协作效率。

### 3. 获取用户设备，支持长段文字的发送，已读未读状态，前端优化
* **🛠 具体实现逻辑**:
  * 后端通过解析 `User-Agent` 获取设备信息并用于用户信息展示；消息模型新增已读状态并提供“已读标记”服务；WebSocket Hub 支持 `read_ack` 类型消息，读取回执时更新数据库而非重复写入普通消息。
  * 前端输入框支持自适应高度与 `Shift+Enter` 换行；消息列表按同一发送者分组渲染，优化头像显示与气泡连贯性；最后一条自己的消息展示 `Delivered/Read` 状态；切换会话或收到新消息时自动发送已读回执。
  * 侧边栏状态信息改为设备信息展示，减少用户误操作与编辑状态复杂度。
* **💻 关键代码变动**:
  * 后端：新增 `backend/pkg/utils/device.go`（设备解析）；`backend/internal/handlers/user.go` 接入设备信息；`backend/internal/models/message.go` 与 `backend/internal/service/message.go` 支持已读标记；`backend/internal/ws/hub.go` 处理 `read_ack`；`backend/internal/ws/client.go` 发送/处理新类型消息。
  * 前端：`frontend/src/components/chat/ChatInput.vue`（自动高度、换行键）；`ChatWindow.vue`（监听消息/会话触发回执）；`MessageList.vue`/`MessageBubble.vue`（分组与已读展示）；`frontend/src/stores/chat.ts`（`isRead` 字段与回执逻辑）；`frontend/src/components/sidebar/MainNav.vue`（设备信息展示）。
* **💡 改进点**:
  * 已读回执让消息状态更可感知；输入自适应提高长文本体验；分组渲染降低视觉噪音；设备信息替代可编辑标签减少状态编辑复杂度并提升可信度。
