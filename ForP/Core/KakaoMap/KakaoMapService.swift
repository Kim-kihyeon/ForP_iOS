import Foundation

final class KakaoMapService {
    static let shared = KakaoMapService()
    private init() {}

    // TODO: 카카오맵 키워드 검색 API 구현
    func searchPlace(keyword: String) async throws -> [CoursePlace] {
        return []
    }
}
