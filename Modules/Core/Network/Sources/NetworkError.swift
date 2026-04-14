import Foundation

public enum NetworkError: Error, LocalizedError {
    case unauthorized
    case notFound
    case serverError(Int)
    case decodingFailed(Error)
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .unauthorized: return "인증이 필요합니다."
        case .notFound: return "리소스를 찾을 수 없습니다."
        case .serverError(let code): return "서버 오류 (\(code))"
        case .decodingFailed: return "데이터 파싱에 실패했습니다."
        case .unknown(let error): return error.localizedDescription
        }
    }
}
