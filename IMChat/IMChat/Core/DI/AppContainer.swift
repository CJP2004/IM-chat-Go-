/*
FILE-GUIDE: AppContainer.swift
- 依赖注入容器（DI Container）：统一创建 Repository、ViewModel、Service。
- 目标：把“对象创建逻辑”集中，页面层只负责使用。
- 典型数据流：View -> ViewModel -> Repository -> APIClient/WebSocketService。
- 如果你要替换实现（例如 Mock API），优先改这里的装配逻辑。
*/

import Foundation
import Combine

@MainActor
final class AppContainer: ObservableObject {
    let apiClient: APIClientProtocol
    let webSocketService: WebSocketService
    let sessionStore: AppSessionStore

    let authRepository: AuthRepository
    let chatRepository: ChatRepository
    let profileRepository: ProfileRepository

    let authViewModel: AuthViewModel
    let chatListViewModel: ChatListViewModel
    let profileViewModel: ProfileViewModel

    /// 使用外部传入依赖完成整套对象装配，方便测试替换实现。
    init(
        apiClient: APIClientProtocol,
        webSocketService: WebSocketService,
        sessionStorage: SessionStorage
    ) {
        self.apiClient = apiClient
        self.webSocketService = webSocketService

        let sessionStore = AppSessionStore(storage: sessionStorage)
        self.sessionStore = sessionStore

        let authRepository = AuthRepositoryImpl(apiClient: apiClient)
        let chatRepository = ChatRepositoryImpl(apiClient: apiClient)
        let profileRepository = ProfileRepositoryImpl(apiClient: apiClient)

        self.authRepository = authRepository
        self.chatRepository = chatRepository
        self.profileRepository = profileRepository

        self.authViewModel = AuthViewModel(
            sessionStore: sessionStore,
            authRepository: authRepository,
            webSocketService: webSocketService
        )
        self.chatListViewModel = ChatListViewModel(
            chatRepository: chatRepository,
            tokenProvider: { [weak sessionStore] in sessionStore?.token }
        )
        self.profileViewModel = ProfileViewModel(repository: profileRepository)
    }

    /// 生产环境默认装配入口（真实 APIClient + 单例 WebSocket + 本地会话存储）。
    convenience init() {
        self.init(
            apiClient: APIClient(),
            webSocketService: WebSocketService.shared,
            sessionStorage: UserDefaultsSessionStorage()
        )
    }

    /// 为指定会话对象创建独立 ChatViewModel，并注入当前 token 提供器。
    func makeChatViewModel(receiver: User, currentUserId: Int?) -> ChatViewModel {
        ChatViewModel(
            receiver: receiver,
            currentUserId: currentUserId,
            chatRepository: chatRepository,
            tokenProvider: { [weak self] in self?.sessionStore.token },
            webSocketService: webSocketService
        )
    }
}
