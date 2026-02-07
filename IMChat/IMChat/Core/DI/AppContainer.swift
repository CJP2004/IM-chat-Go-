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

    convenience init() {
        self.init(
            apiClient: APIClient(),
            webSocketService: WebSocketService.shared,
            sessionStorage: UserDefaultsSessionStorage()
        )
    }

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
