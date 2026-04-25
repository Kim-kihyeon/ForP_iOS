import Foundation
import Moya

public enum GPTTarget {
    case generateCourse(systemMessage: String, prompt: String)
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
        case .generateCourse(let systemMessage, let prompt):
            let body: [String: Any] = [
                "model": "gpt-4o",
                "max_tokens": 2000,
                "messages": [
                    ["role": "system", "content": systemMessage],
                    ["role": "user", "content": prompt],
                ],
                "response_format": [
                    "type": "json_schema",
                    "json_schema": [
                        "name": "course_plan",
                        "strict": true,
                        "schema": [
                            "type": "object",
                            "properties": [
                                "courseReason": ["type": "string"],
                                "courses": [
                                    "type": "array",
                                    "items": [
                                        "type": "object",
                                        "properties": [
                                            "order": ["type": "integer"],
                                            "category": ["type": "string"],
                                            "keyword": ["type": "string"],
                                            "reason": ["type": "string"],
                                            "menu": ["anyOf": [["type": "string"], ["type": "null"]]],
                                            "isSelected": ["type": "boolean"],
                                        ] as [String: Any],
                                        "required": ["order", "category", "keyword", "reason", "menu", "isSelected"],
                                        "additionalProperties": false,
                                    ] as [String: Any],
                                ] as [String: Any],
                                "outfit": ["type": "string"],
                            ] as [String: Any],
                            "required": ["courseReason", "courses", "outfit"],
                            "additionalProperties": false,
                        ] as [String: Any],
                    ] as [String: Any],
                ] as [String: Any],
            ]
            return .requestParameters(parameters: body, encoding: JSONEncoding.default)
        }
    }

    public var headers: [String: String]? { nil }
}
