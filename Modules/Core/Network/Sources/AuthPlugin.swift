import Foundation
import Moya

public struct AuthPlugin: PluginType {
    private let tokenProvider: @Sendable () -> String?

    public init(tokenProvider: @escaping @Sendable () -> String?) {
        self.tokenProvider = tokenProvider
    }

    public func prepare(_ request: URLRequest, target: any TargetType) -> URLRequest {
        guard let token = tokenProvider() else { return request }
        var request = request
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
}
