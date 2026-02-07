/*
FILE-GUIDE: ProfileRepository.swift
- 个人资料模块数据层。
- 头像更新流程：先上传文件拿 URL，再提交头像 URL 更新用户信息。
- 接口调用需要 token。
*/

import Foundation

protocol ProfileRepository {
    func uploadAvatarImage(data: Data, filename: String, token: String?) async throws -> String
    func updateAvatar(avatarURL: String, token: String?) async throws -> String
}

struct ProfileRepositoryImpl: ProfileRepository {
    private struct AvatarPayload: Encodable {
        let avatar: String
    }

    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }

    func uploadAvatarImage(data: Data, filename: String, token: String?) async throws -> String {
        let uploadRequest = UploadImageRequest(data: data, filename: filename)
        return try await apiClient.uploadImage(uploadRequest, token: token)
    }

    func updateAvatar(avatarURL: String, token: String?) async throws -> String {
        let request = try APIRequest<AvatarResponse>.json(
            path: "/api/user/avatar",
            method: .PUT,
            body: AvatarPayload(avatar: avatarURL)
        )
        let response = try await apiClient.send(request, token: token)
        return response.avatar
    }
}
