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
}
