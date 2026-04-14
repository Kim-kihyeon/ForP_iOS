import Foundation
import Moya

public enum GPTTarget {
    case generateCourse(prompt: String)
}

extension GPTTarget: TargetType {
    public var baseURL: URL { URL(string: "https://api.openai.com")! }

    public var path: String {
        switch self {
        case .generateCourse: return "/v1/chat/completions"
        }
    }

    public var method: Moya.Method { .post }

    public var task: Task {
        switch self {
        case .generateCourse(let prompt):
            let body: [String: Any] = [
                "model": "gpt-4o",
                "messages": [
                    ["role": "user", "content": prompt]
                ],
                "response_format": ["type": "json_object"],
            ]
            return .requestParameters(parameters: body, encoding: JSONEncoding.default)
        }
    }

    public var headers: [String: String]? { nil }
}
