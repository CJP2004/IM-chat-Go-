import Foundation

/// 网络请求错误枚举
enum APIError: Error {
    case invalidURL
    case requestFailed
    case decodingFailed
    case custom(message: String)
}

/// HTTP 方法枚举
enum HTTPMethod: String {
    case GET
    case POST
}

/// API 服务管理类 (单例)
class APIService {
    static let shared = APIService()
    
    private init() {}
    
    /// 通用请求方法
    /// - Parameters:
    ///   - endpoint: API 端点 (例如 "/login")
    ///   - method: HTTP 方法
    ///   - body: 请求体 (可选)
    ///   - token: 授权 Token (可选)
    /// - Returns: 解码后的响应数据
    func request<T: Decodable>(endpoint: String, method: HTTPMethod = .GET, body: [String: Any]? = nil, token: String? = nil) async throws -> T {
        guard let url = URL(string: Constants.baseURL + endpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
            } catch {
                throw APIError.custom(message: "Failed to encode request body")
            }
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.requestFailed
            }
            
            // 解码为标准响应
            let backendResponse = try JSONDecoder().decode(BackendResponse<T>.self, from: data)
            
            // 检查业务状态码
            if backendResponse.code == 200 {
                return backendResponse.data
            } else {
                throw APIError.custom(message: backendResponse.msg)
            }
        } catch let parsingError as DecodingError {
            print("Decoding error: \(parsingError)")
            throw APIError.decodingFailed
        } catch {
            throw error
        }
    }
}

// 定义标准响应结构 (对应 Go 后端 pkg/response/response.go)
fileprivate struct BackendResponse<U: Decodable>: Decodable {
    let code: Int
    let msg: String
    let data: U
}
