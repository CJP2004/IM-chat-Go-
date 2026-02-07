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

    init(repository: ProfileRepository) {
        self.repository = repository
    }

    func clearError() {
        errorMessage = nil
    }

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
