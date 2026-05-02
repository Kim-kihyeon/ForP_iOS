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
                        continuation.resume(returning: Self.deduplicated(dto.documents, keyword: keyword))
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
            provider.request(.searchKeyword(query: keyword, x: "\(longitude)", y: "\(latitude)", radius: radius, size: 15)) { result in
                switch result {
                case .success(let response):
                    do {
                        let dto = try JSONDecoder().decode(KakaoSearchResponse.self, from: response.data)
                        continuation.resume(returning: Self.deduplicatedForCourse(dto.documents, keyword: keyword))
                    } catch {
                        continuation.resume(throwing: error)
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private static let excludedCategoryCodes: Set<String> = [
        "SW8", "PK6", "SC4", "OL7", "BK9", "PO3", "CS2",
        "HP8", "PM9", "PS3", "AC5", "AG2", "MT1",
    ]

    private static let excludedNameKeywords: [String] = [
        "아파트", "빌라", "오피스텔", "주차장", "지하철역", "고속버스터미널",
        "버스터미널", "기차역", "주유소", "편의점",
        "병원", "약국", "장례식장", "동사무소", "주민센터", "구청", "세무서",
    ]

    private static let excludedChainKeywords: [String] = [
        "메가커피", "메가MGC커피", "컴포즈커피", "빽다방", "이디야", "스타벅스",
        "투썸플레이스", "할리스", "커피빈", "폴바셋", "엔제리너스", "파스쿠찌",
        "공차", "더벤티", "매머드커피", "커피에반하다", "커피베이", "탐앤탐스",
        "요거프레소", "커피나무", "하삼동커피", "텐퍼센트커피",
    ]

    private static func toPlace(_ doc: KakaoPlaceDTO, keyword: String) -> CoursePlace {
        CoursePlace(
            order: 0, category: "", keyword: keyword, reason: "",
            placeName: doc.placeName, address: doc.addressName,
            latitude: Double(doc.y), longitude: Double(doc.x),
            kakaoPlaceId: doc.id
        )
    }

    private static func deduplicated(_ documents: [KakaoPlaceDTO], keyword: String) -> [CoursePlace] {
        var seen = Set<String>()
        return documents.compactMap { doc in
            guard !seen.contains(doc.id) else { return nil }
            seen.insert(doc.id)
            return toPlace(doc, keyword: keyword)
        }
    }

    private static func deduplicatedForCourse(_ documents: [KakaoPlaceDTO], keyword: String) -> [CoursePlace] {
        var seen = Set<String>()
        let eligible = documents.filter { doc in
            guard !seen.contains(doc.id) else { return false }
            guard !excludedCategoryCodes.contains(doc.categoryGroupCode) else { return false }
            guard !excludedNameKeywords.contains(where: { doc.placeName.contains($0) || doc.categoryName.contains($0) }) else { return false }
            seen.insert(doc.id)
            return true
        }
        let localFirst = eligible.filter { doc in
            !excludedChainKeywords.contains { doc.placeName.localizedCaseInsensitiveContains($0) }
        }
        let chains = eligible.filter { doc in
            excludedChainKeywords.contains { doc.placeName.localizedCaseInsensitiveContains($0) }
        }
        return (localFirst + chains).map { doc in
            toPlace(doc, keyword: keyword)
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
