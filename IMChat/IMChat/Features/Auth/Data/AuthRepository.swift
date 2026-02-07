/*
FILE-GUIDE: AuthRepository.swift
- 认证模块数据层：只关心登录/注册接口调用。
- 作用：把请求细节从 ViewModel 中抽离，便于测试和替换。
- 返回 LoginResponse（token + user），供上层写入会话。
*/

import Foundation

protocol AuthRepository {
    func register(username: String, password: String) async throws -> LoginResponse
    func login(username: String, password: String) async throws -> LoginResponse
}

struct AuthRepositoryImpl: AuthRepository {
    private struct CredentialsPayload: Encodable {
        let username: String
        let password: String
    }

    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }

    func register(username: String, password: String) async throws -> LoginResponse {
        let request = try APIRequest<LoginResponse>.json(
            path: "/api/register",
            method: .POST,
            body: CredentialsPayload(username: username, password: password)
        )
        return try await apiClient.send(request, token: nil)
    }

    func login(username: String, password: String) async throws -> LoginResponse {
        let request = try APIRequest<LoginResponse>.json(
            path: "/api/login",
            method: .POST,
            body: CredentialsPayload(username: username, password: password)
        )
        return try await apiClient.send(request, token: nil)
    }
}
