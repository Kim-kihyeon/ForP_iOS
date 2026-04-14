import Foundation
import Moya

public struct AuthPlugin: PluginType {
    private let tokenProvider: @Sendable () -> String?
    private let prefix: String

    public init(prefix: String = "Bearer", tokenProvider: @escaping @Sendable () -> String?) {
        self.prefix = prefix
        self.tokenProvider = tokenProvider
    }

    public func prepare(_ request: URLRequest, target: any TargetType) -> URLRequest {
        guard let token = tokenProvider() else { return request }
        var request = request
        request.addValue("\(prefix) \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
}
