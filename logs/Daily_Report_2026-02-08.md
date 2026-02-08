# IM-Chat 深度技术日报

- 时间范围：过去 24 小时（截至 2026-02-08）
- 生成依据：`git log --all -p --since="24 hours ago" --reverse`

### 1. 优化架构
* **🛠 具体实现逻辑**:
    * 前端进行目录与职责重构，采用 `App / Core / Features / Shared` 分层，把应用入口、路由、依赖注入、会话与网络抽象统一到核心层，再由功能模块（Auth / Chat / Profile）通过 Repository + ViewModel 对外提供业务能力。
    * 新增 `AppContainer` 作为 DI 入口，集中装配 `APIClient`、`WebSocketService`、`SessionStore` 与各业务 Repository，配合 `ContentView` 和 `MainTabView` 实现登录态路由切换与模块化装配。
    * 网络与实时通信统一：引入 `APIClient` 作为 REST 调用的单一出口，`WebSocketService` 负责连接、发送、重连与接收；消息模型进行 DTO -> Domain 转换并通过 `stableId` 统一前端去重和排序。
    * 会话管理改为 `AppSessionStore + SessionStorage` 双层结构，token 走 Keychain，用户缓存走 UserDefaults，并实现旧 token 迁移逻辑，确保登录态可恢复。
    * 后端补齐鉴权闭环：新增 `HTTPAuth` 中间件解析 `Authorization: Bearer <token>` 并注入 `userID`；HTTP 路由与 WS 入口均统一启用鉴权。
    * 历史消息接口改为分页语义，从 token 取 `senderId`，新增 `page/pageSize` 参数并限制范围；WS 消息落库后回写 `messageId`，并同时回执给发送方用于前端确认乐观消息。
    * WS Hub 增强容错，消息持久化或已读更新失败时不再退出主循环，改为记录日志后继续服务，避免实时服务整体中断。
    * 配置与安全治理：`.gitignore` 增加 `.env` 相关规则，避免敏感配置入库；同时补齐后端响应封装与部分 handler 的边界清晰化。

* **💻 关键代码变动**:
    * 前端架构重排与新增：
        * 入口与路由：`IMChat/IMChat/App/IMChatApp.swift`、`IMChat/IMChat/App/ContentView.swift`、`IMChat/IMChat/App/MainTabView.swift`。
        * 依赖注入：`IMChat/IMChat/Core/DI/AppContainer.swift`。
        * 网络与实时：`IMChat/IMChat/Core/Networking/APIClient.swift`、`IMChat/IMChat/Core/Realtime/WebSocketService.swift`。
        * 会话与存储：`IMChat/IMChat/Core/Session/AppSessionStore.swift`、`IMChat/IMChat/Core/Session/SessionStorage.swift`。
        * 业务层：
            * Auth：`IMChat/IMChat/Features/Auth/Data/AuthRepository.swift`、`IMChat/IMChat/Features/Auth/Presentation/AuthViewModel.swift`、`IMChat/IMChat/Features/Auth/Presentation/LoginView.swift`。
            * Chat：`IMChat/IMChat/Features/Chat/Data/ChatRepository.swift`、`IMChat/IMChat/Features/Chat/Presentation/ChatViewModel.swift`、`IMChat/IMChat/Features/Chat/Presentation/ChatRoomView.swift`、`IMChat/IMChat/Features/Chat/Presentation/ChatListView.swift`。
            * Profile：`IMChat/IMChat/Features/Profile/Data/ProfileRepository.swift`、`IMChat/IMChat/Features/Profile/Presentation/ProfileView.swift`、`IMChat/IMChat/Features/Profile/Presentation/ProfileViewModel.swift`。
        * 模型/工具重定位：`IMChat/IMChat/Shared/Models/User.swift`、`IMChat/IMChat/Shared/Utilities/DateHelper.swift`、`IMChat/IMChat/Shared/Theme/ThemeManager.swift`。
        * 移除旧结构与重复实现：`IMChat/IMChat/Services/`、`IMChat/IMChat/ViewModels/`、`IMChat/IMChat/Views/` 等旧模块被替换为新的 Feature 结构。
    * 后端安全与协议改造：
        * 鉴权中间件：`backend/internal/middleware/auth.go`（解析 Bearer Token，注入 `userID`）。
        * 路由保护：`backend/internal/router/router.go`（`/users`、`/upload`、`/messages`、`/user/*` 挂载鉴权组；WS 使用中间件）。
        * 历史消息分页与身份改造：`backend/internal/handlers/message.go`（senderId 来自 token，新增 `page/pageSize` 参数校验）。
        * WS 安全与回执：`backend/internal/ws/client.go`（WS 从 token 获取用户；广播也统一走结构化消息），`backend/internal/ws/hub.go`（保存消息后回写 `MessageID`，回执给发送方，错误不再中断主循环）。
        * 消息持久化接口升级：`backend/internal/service/message.go`、`backend/internal/models/message.go`（保存函数返回 `messageId`，为回执与确认链路打基础）。
        * 响应封装与 JWT：`backend/pkg/response/response.go`、`backend/pkg/utils/jwt.go`（错误码与鉴权响应更一致）。
    * 新增架构评估文档：`Architecture_Review_Frontend_Backend_2026-02-07.md`。

* **💡 改进点**:
    * 前端职责边界更清晰：UI 与数据/网络解耦，测试与替换网络实现更容易，业务扩展不再依赖全局单例。
    * 登录态与实时连接形成闭环，token 来源统一，避免了“前端伪造 senderId”与“WS Query 注入”的安全漏洞。
    * 历史消息分页协议对齐，能支撑长会话与弱网加载；WS 回执链路使乐观消息可可靠确认。
    * Hub 容错增强降低单点故障风险，后端日志可定位持久化失败而不中断服务。

### 2. 注释
* **🛠 具体实现逻辑**:
    * 对核心 Swift 代码补充文档注释，覆盖会话管理、网络层、实时通信、Repository、ViewModel 与 UI 交互要点；强调 token 存储策略、分页加载策略、消息排序与稳定 ID 的来源。
    * 架构评估文档进行内容更新与梳理，强化“安全/鉴权/协议一致性”的风险与建议描述。

* **💻 关键代码变动**:
    * 文档注释覆盖文件：
        * 会话与存储：`IMChat/IMChat/Core/Session/SessionStorage.swift`、`IMChat/IMChat/Core/Session/AppSessionStore.swift`。
        * 网络与 WS：`IMChat/IMChat/Core/Networking/APIClient.swift`、`IMChat/IMChat/Core/Realtime/WebSocketService.swift`。
        * Repository 与 ViewModel：`IMChat/IMChat/Features/Auth/Data/AuthRepository.swift`、`IMChat/IMChat/Features/Auth/Presentation/AuthViewModel.swift`、`IMChat/IMChat/Features/Chat/Data/ChatRepository.swift`、`IMChat/IMChat/Features/Chat/Presentation/ChatViewModel.swift`、`IMChat/IMChat/Features/Profile/Data/ProfileRepository.swift`、`IMChat/IMChat/Features/Profile/Presentation/ProfileViewModel.swift`。
        * DTO/工具：`IMChat/IMChat/Features/Chat/Domain/Models/RESTMessageDTO.swift`、`IMChat/IMChat/Features/Chat/Domain/Models/WSMessageDTO.swift`、`IMChat/IMChat/Shared/Utilities/DateHelper.swift`。
        * 交互组件：`IMChat/IMChat/Features/Profile/Presentation/Components/ImagePicker.swift`、`IMChat/IMChat/Features/Chat/Presentation/ChatRoomView.swift`。
    * 评审文档更新：`Architecture_Review_Frontend_Backend_2026-02-07.md`（内容增补与整理）。

* **💡 改进点**:
    * 文档化使关键链路（登录、会话恢复、历史加载、WS 消息确认）更容易被新成员理解，降低维护成本。
    * 强化约定说明与参数语义，减少“接口表意不一致”导致的前后端偏差。

