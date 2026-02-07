/*
FILE-GUIDE: ChatRepository.swift
- 聊天模块数据层：联系人列表 + 历史消息。
- 当前安全策略：所有请求都带 token（由上层传入）。
- 历史消息会做 DTO -> Domain 映射，并做稳定排序，保证 UI 渲染顺序一致。
*/

import Foundation

protocol ChatRepository {
    /// 拉取联系人列表（会附带最近一条消息摘要等信息）。
    func fetchUsers(currentUserId: Int, token: String) async throws -> [User]
    /// 按会话对象和分页参数拉取历史消息。
    func fetchHistory(
        currentUserId: Int,
        receiverId: Int,
        page: Int,
        pageSize: Int,
        token: String
    ) async throws -> [ChatMessage]
}

struct ChatRepositoryImpl: ChatRepository {
    private let apiClient: APIClientProtocol

    /// 注入网络客户端，便于替换真实实现或做单元测试。
    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }

    /// 请求联系人列表接口并返回用户数组。
    func fetchUsers(currentUserId _: Int, token: String) async throws -> [User] {
        let request = APIRequest<[User]>(
            path: "/api/users",
            method: .GET
        )
        return try await apiClient.send(request, token: token)
    }

    /// 请求历史消息接口，完成 DTO 映射并按时间/ID 做稳定排序。
    func fetchHistory(
        currentUserId _: Int,
        receiverId: Int,
        page: Int,
        pageSize: Int,
        token: String
    ) async throws -> [ChatMessage] {
        let request = APIRequest<[RESTMessageDTO]>(
            path: "/api/messages",
            method: .GET,
            queryItems: [
                URLQueryItem(name: "receiverId", value: String(receiverId)),
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "pageSize", value: String(pageSize)),
            ]
        )
        let response = try await apiClient.send(request, token: token)
        return response
            .map { $0.toDomain() }
            .sorted(by: Self.isMessageEarlier(_:_:))
    }

    /// 比较两条消息的先后顺序：优先比时间，再比服务端ID，最后比稳定ID。
    private static func isMessageEarlier(_ lhs: ChatMessage, _ rhs: ChatMessage) -> Bool {
        let lhsDate = parseDate(lhs.createdAt)
        let rhsDate = parseDate(rhs.createdAt)

        switch (lhsDate, rhsDate) {
        case let (left?, right?) where left != right:
            return left < right
        default:
            break
        }

        if let lhsId = lhs.serverMessageId, let rhsId = rhs.serverMessageId, lhsId != rhsId {
            return lhsId < rhsId
        }

        return lhs.stableId < rhs.stableId
    }

    /// 兼容多种后端时间格式，尽量把字符串解析成 Date。
    private static func parseDate(_ value: String?) -> Date? {
        guard let value, !value.isEmpty else { return nil }

        if let isoDate = iso8601WithFractional.date(from: value) ?? iso8601.date(from: value) {
            return isoDate
        }

        for formatter in fallbackDateFormatters {
            if let date = formatter.date(from: value) {
                return date
            }
        }

        return nil
    }

    private static let iso8601WithFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static let fallbackDateFormatters: [DateFormatter] = {
        let formats = [
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd HH:mm",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
        ]

        return formats.map { format in
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = format
            return formatter
        }
    }()
}
