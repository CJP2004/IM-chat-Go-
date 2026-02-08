/*
FILE-GUIDE: ProfileViewModel.swift
- 设置/个人页的业务状态管理。
- 核心动作是上传头像，并维护上传中和错误提示状态。
- 视图层只负责触发动作和展示状态，不直接写上传流程。
*/

import SwiftUI
import UIKit
import Combine

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var isUploading = false
    @Published var errorMessage: String?

    private let repository: ProfileRepository

    /// 注入个人资料数据层依赖。
    init(repository: ProfileRepository) {
        self.repository = repository
    }

    /// 清空页面错误提示，通常在弹窗关闭后调用。
    func clearError() {
        errorMessage = nil
    }

    /// 头像上传总流程：图片压缩 -> token 校验 -> 上传文件 -> 更新头像字段。
    func uploadAvatar(
        image: UIImage,
        token: String?
    ) async -> String? {
        guard let data = image.jpegData(compressionQuality: 0.85) else {
            errorMessage = "Image processing failed."
            return nil
        }

        guard let token, !token.isEmpty else {
            errorMessage = "Session expired. Please log in again."
            return nil
        }

        isUploading = true
        defer { isUploading = false }

        do {
            let uploadURL = try await repository.uploadAvatarImage(
                data: data,
                filename: "avatar.jpg",
                token: token
            )
            let avatarURL = try await repository.updateAvatar(
                avatarURL: uploadURL,
                token: token
            )
            return avatarURL
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
