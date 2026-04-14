import Foundation

final class FetchPlacesUseCase {
    func execute(places: [CoursePlace]) async throws -> [CoursePlace] {
        // TODO: KakaoMapService로 keyword 검색 → 실제 장소 정보 채워서 반환
        return places
    }
}
