import Foundation
import Moya

public enum KakaoTarget {
    case searchKeyword(query: String, x: String? = nil, y: String? = nil, radius: Int? = nil)
}

extension KakaoTarget: TargetType {
    public var baseURL: URL { URL(string: "https://dapi.kakao.com")! }

    public var path: String { "/v2/local/search/keyword.json" }

    public var method: Moya.Method { .get }

    public var task: Task {
        switch self {
        case .searchKeyword(let query, let x, let y, let radius):
            var params: [String: Any] = ["query": query]
            if let x { params["x"] = x }
            if let y { params["y"] = y }
            if let radius { params["radius"] = radius }
            return .requestParameters(parameters: params, encoding: URLEncoding.queryString)
        }
    }

    public var headers: [String: String]? { nil }
}
