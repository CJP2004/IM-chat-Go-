import Foundation

/// 网络请求错误枚举
enum APIError: Error, LocalizedError {
    case invalidURL
    case requestFailed
    case decodingFailed
    case custom(message: String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .requestFailed: return "Request failed"
        case .decodingFailed: return "Decoding failed"
        case .custom(let message): return message
        }
    }
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
            
            // 尝试打印原始数据以调试 (Optional)
             if let str = String(data: data, encoding: .utf8) {
                 print("API Response: \(str)")
             }
            
            // 解码为标准响应
            let backendResponse = try JSONDecoder().decode(BackendResponse<T>.self, from: data)
            
            // 检查业务状态码
            if backendResponse.code == 200 {
                // 确保 data 存在
                if let data = backendResponse.data {
                    return data
                } else {
                     throw APIError.custom(message: "Missing data in successful response")
                }
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
// data 设为可选，因为报错时 info/data 肯能为空
fileprivate struct BackendResponse<U: Decodable>: Decodable {
    let code: Int
    let msg: String
    let data: U?
}
