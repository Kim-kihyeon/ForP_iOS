import Foundation

public enum CourseGenerationError: LocalizedError {
    case invalidLocation(String)

    public var errorDescription: String? {
        switch self {
        case .invalidLocation(let location):
            return "'\(location)'을 찾을 수 없어요. 올바른 지역명을 입력해주세요. (예: 강남, 홍대, 성수동)"
        }
    }
}

public struct GenerateCourseUseCase {
    private let aiService: any AIServiceProtocol
    private let placeRepository: any PlaceRepositoryProtocol

    public init(aiService: any AIServiceProtocol, placeRepository: any PlaceRepositoryProtocol) {
        self.aiService = aiService
        self.placeRepository = placeRepository
    }

    public func execute(user: User, partner: Partner?, options: CourseOptions) async throws -> CoursePlan {
        let isValid = try await placeRepository.isValidKoreanRegion(keyword: options.location)
        guard isValid else {
            throw CourseGenerationError.invalidLocation(options.location)
        }

        let plan = try await aiService.generateCoursePlan(user: user, partner: partner, options: options)
        var enriched: [CoursePlace] = []
        for place in plan.places {
            let results = try await placeRepository.searchPlaces(keyword: place.keyword)
            if let first = results.first {
                var updated = place
                updated.placeName = first.placeName
                updated.address = first.address
                updated.latitude = first.latitude
                updated.longitude = first.longitude
                enriched.append(updated)
            } else {
                enriched.append(place)
            }
        }
        return CoursePlan(places: enriched, outfitSuggestion: plan.outfitSuggestion)
    }
}
