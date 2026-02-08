/*
FILE-GUIDE: ProfileRepository.swift
- 个人资料模块数据层。
- 头像更新流程：先上传文件拿 URL，再提交头像 URL 更新用户信息。
- 接口调用需要 token。
*/

import Foundation

protocol ProfileRepository {
    /// 上传头像原始数据到文件服务，返回可访问图片地址。
    func uploadAvatarImage(data: Data, filename: String, token: String?) async throws -> String
    /// 把头像 URL 提交到用户资料接口并返回最终头像地址。
    func updateAvatar(avatarURL: String, token: String?) async throws -> String
}

struct ProfileRepositoryImpl: ProfileRepository {
    private struct AvatarPayload: Encodable {
        let avatar: String
    }

    private let apiClient: APIClientProtocol

    /// 注入 API 客户端，便于替换网络实现。
    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }

    /// 执行第一步头像上传（multipart 文件上传）。
    func uploadAvatarImage(data: Data, filename: String, token: String?) async throws -> String {
        let uploadRequest = UploadImageRequest(data: data, filename: filename)
        return try await apiClient.uploadImage(uploadRequest, token: token)
    }

    /// 执行第二步资料更新（把上传后 URL 写入用户头像字段）。
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
