/*
FILE-GUIDE: APIClient.swift
- 通用网络层：封装请求构建、鉴权头、响应解析、错误转换。
- 核心点：
  1) APIRequest 定义请求元信息（path/method/query/body）。
  2) send() 统一处理 wrapped/raw 两种响应风格。
  3) uploadImage() 单独处理 multipart 上传。
- 调试顺序：先看 request 组装，再看后端返回是否匹配 Decodable 模型。
*/

import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case requestFailed
    case decodingFailed
    case custom(message: String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .requestFailed:
            return "Request failed"
        case .decodingFailed:
            return "Decoding failed"
        case .custom(let message):
            return message
        }
    }
}

enum HTTPMethod: String {
    case GET
    case POST
    case PUT
}

enum APIResponseStyle {
    case wrapped
    case raw
}

struct APIRequest<Response: Decodable> {
    let path: String
    let method: HTTPMethod
    let queryItems: [URLQueryItem]
    let headers: [String: String]
    let body: Data?
    let responseStyle: APIResponseStyle

    /// 创建一个通用 API 请求对象（路径、方法、查询、头、包体、响应风格）。
    init(
        path: String,
        method: HTTPMethod = .GET,
        queryItems: [URLQueryItem] = [],
        headers: [String: String] = [:],
        body: Data? = nil,
        responseStyle: APIResponseStyle = .wrapped
    ) {
        self.path = path
        self.method = method
        self.queryItems = queryItems
        self.headers = headers
        self.body = body
        self.responseStyle = responseStyle
    }
}

extension APIRequest {
    /// 快速构建 JSON 请求：自动编码 body，并在需要时补 `Content-Type: application/json`。
    static func json<Body: Encodable>(
        path: String,
        method: HTTPMethod = .GET,
        queryItems: [URLQueryItem] = [],
        body: Body? = nil,
        headers: [String: String] = [:],
        responseStyle: APIResponseStyle = .wrapped,
        encoder: JSONEncoder = JSONEncoder()
    ) throws -> APIRequest<Response> {
        let encodedBody: Data?
        if let body {
            encodedBody = try encoder.encode(body)
        } else {
            encodedBody = nil
        }

        var mergedHeaders = headers
        if encodedBody != nil, mergedHeaders["Content-Type"] == nil {
            mergedHeaders["Content-Type"] = "application/json"
        }

        return APIRequest<Response>(
            path: path,
            method: method,
            queryItems: queryItems,
            headers: mergedHeaders,
            body: encodedBody,
            responseStyle: responseStyle
        )
    }
}

struct UploadImageRequest {
    let data: Data
    let filename: String
    let mimeType: String
    let path: String

    /// 创建上传图片请求参数（数据、文件名、MIME、接口路径）。
    init(
        data: Data,
        filename: String,
        mimeType: String = "image/jpeg",
        path: String = "/api/upload"
    ) {
        self.data = data
        self.filename = filename
        self.mimeType = mimeType
        self.path = path
    }
}

protocol APIClientProtocol {
    /// 发送 HTTP 请求并把响应解码为泛型模型。
    func send<Response: Decodable>(_ request: APIRequest<Response>, token: String?) async throws -> Response
    /// 上传图片并返回后端返回的可访问 URL。
    func uploadImage(_ request: UploadImageRequest, token: String?) async throws -> String
}

final class APIClient: APIClientProtocol {
    private let baseURL: String
    private let urlSession: URLSession
    private let decoder: JSONDecoder

    /// 创建网络客户端，支持注入 baseURL、URLSession 和解码器。
    init(
        baseURL: String,
        urlSession: URLSession = .shared,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.baseURL = baseURL
        self.urlSession = urlSession
        self.decoder = decoder
    }

    /// 使用全局配置的 `Constants.baseURL` 初始化网络客户端。
    convenience init() {
        self.init(baseURL: Constants.baseURL)
    }

    /// 统一执行 API 请求：组装 URLRequest、附加鉴权头、按响应风格解码结果。
    func send<Response: Decodable>(
        _ request: APIRequest<Response>,
        token: String? = nil
    ) async throws -> Response {
        guard var components = URLComponents(string: baseURL + request.path) else {
            throw APIError.invalidURL
        }
        if !request.queryItems.isEmpty {
            components.queryItems = request.queryItems
        }
        guard let url = components.url else {
            throw APIError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.httpBody = request.body
        request.headers.forEach { key, value in
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        if let token {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await urlSession.data(for: urlRequest)
        } catch {
            throw APIError.custom(message: "Network error: \(error.localizedDescription)")
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.requestFailed
        }

        switch request.responseStyle {
        case .wrapped:
            return try decodeWrappedResponse(data: data)
        case .raw:
            guard (200...299).contains(httpResponse.statusCode) else {
                throw APIError.custom(message: "Request failed, status code: \(httpResponse.statusCode)")
            }
            do {
                return try decoder.decode(Response.self, from: data)
            } catch {
                throw APIError.decodingFailed
            }
        }
    }

    /// 执行 multipart 图片上传，并从响应中解析出最终图片 URL。
    func uploadImage(_ request: UploadImageRequest, token: String? = nil) async throws -> String {
        guard let url = URL(string: baseURL + request.path) else {
            throw APIError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = HTTPMethod.POST.rawValue

        let boundary = "Boundary-\(UUID().uuidString)"
        urlRequest.setValue(
            "multipart/form-data; boundary=\(boundary)",
            forHTTPHeaderField: "Content-Type"
        )
        if let token {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        var body = Data()
        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"file\"; filename=\"\(request.filename)\"\r\n")
        body.appendString("Content-Type: \(request.mimeType)\r\n\r\n")
        body.append(request.data)
        body.appendString("\r\n--\(boundary)--\r\n")
        urlRequest.httpBody = body

        let responseData: Data
        let response: URLResponse
        do {
            (responseData, response) = try await urlSession.data(for: urlRequest)
        } catch {
            throw APIError.custom(message: "Upload failed: \(error.localizedDescription)")
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.requestFailed
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.custom(message: "Upload failed, status code: \(httpResponse.statusCode)")
        }

        do {
            let uploadResponse = try decoder.decode(UploadResponse.self, from: responseData)
            return uploadResponse.url
        } catch {
            throw APIError.decodingFailed
        }
    }

    /// 解码后端统一包装体 `{code,msg,data}`，并把业务错误转换为 `APIError`。
    private func decodeWrappedResponse<Response: Decodable>(data: Data) throws -> Response {
        do {
            let backendResponse = try decoder.decode(BackendResponse<Response>.self, from: data)
            if backendResponse.code == 200, let payload = backendResponse.data {
                return payload
            }
            throw APIError.custom(message: backendResponse.msg)
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.decodingFailed
        }
    }
}

private struct BackendResponse<U: Decodable>: Decodable {
    let code: Int
    let msg: String
    let data: U?
}

private struct UploadResponse: Decodable {
    let url: String
}

private extension Data {
    /// 便捷追加 UTF-8 字符串到二进制数据（用于 multipart body 拼装）。
    mutating func appendString(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
