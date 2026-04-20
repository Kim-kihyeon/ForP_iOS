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

    public func searchPlaces(keyword: String, latitude: Double, longitude: Double, radius: Int) async throws -> [CoursePlace] {
        try await withCheckedThrowingContinuation { continuation in
            provider.request(.searchKeyword(query: keyword, x: "\(longitude)", y: "\(latitude)", radius: radius)) { result in
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
                        // 결과가 없으면 무효
                        guard !dto.documents.isEmpty else {
                            continuation.resume(returning: false)
                            return
                        }

                        // 첫 번째 결과 주소에 한글이 있으면 한국 장소로 판단
                        let address = dto.documents[0].addressName
                        let hasHangul = address.unicodeScalars.contains {
                            ($0.value >= 0xAC00 && $0.value <= 0xD7A3) ||
                            ($0.value >= 0x3130 && $0.value <= 0x318F)
                        }
                        continuation.resume(returning: hasHangul)
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
