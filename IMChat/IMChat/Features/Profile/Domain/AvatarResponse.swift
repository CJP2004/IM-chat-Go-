/*
FILE-GUIDE: AvatarResponse.swift
- 头像更新接口返回模型。
- 结构很小，但保留独立类型有助于接口演进和可读性。
*/

import Foundation

/// 更新头像接口返回结构
struct AvatarResponse: Decodable {
    let avatar: String
}
