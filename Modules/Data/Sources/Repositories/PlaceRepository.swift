import Foundation
@preconcurrency import Moya
import Domain

public struct PlaceRepository: PlaceRepositoryProtocol {
    private let provider: MoyaProvider<KakaoTarget>

    public init(provider: MoyaProvider<KakaoTarget>) {
        self.provider = provider
    }

    public func searchPlaces(keyword: String) async throws -> [CoursePlace] {
        try await withCheckedThrowingContinuation { continuation in
            provider.request(.searchKeyword(query: keyword)) { result in
                switch result {
                case .success(let response):
                    do {
                        let dto = try JSONDecoder().decode(KakaoSearchResponse.self, from: response.data)
                        let places = dto.documents.map { doc in
                            CoursePlace(
                                order: 0,
                                category: "",
                                keyword: keyword,
                                reason: "",
                                placeName: doc.placeName,
                                address: doc.addressName,
                                latitude: Double(doc.y),
                                longitude: Double(doc.x)
                            )
                        }
                        continuation.resume(returning: places)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    public func isValidKoreanRegion(keyword: String) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            provider.request(.searchKeyword(query: keyword)) { result in
                switch result {
                case .success(let response):
                    do {
                        let dto = try JSONDecoder().decode(KakaoSearchResponse.self, from: response.data)
                        let selectedRegion = dto.meta.sameName?.selectedRegion ?? ""

                        if !selectedRegion.isEmpty {
                            continuation.resume(returning: true)
                            return
                        }

                        // 폴백: selected_region이 없어도 한국 지역 접미사가 붙으면 허용
                        let koreanSuffixes = ["역", "동", "구", "시", "군", "로", "거리", "마을", "읍", "면"]
                        let hasKoreanSuffix = koreanSuffixes.contains { keyword.hasSuffix($0) }
                        let hasResults = !dto.documents.isEmpty
                        continuation.resume(returning: hasKoreanSuffix && hasResults)
                    } catch {
                        continuation.resume(returning: false)
                    }
                case .failure:
                    continuation.resume(returning: false)
                }
            }
        }
    }
}
