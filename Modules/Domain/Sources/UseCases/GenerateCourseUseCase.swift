import Foundation

public struct GenerateCourseUseCase {
    private let aiService: any AIServiceProtocol
    private let placeRepository: any PlaceRepositoryProtocol

    public init(aiService: any AIServiceProtocol, placeRepository: any PlaceRepositoryProtocol) {
        self.aiService = aiService
        self.placeRepository = placeRepository
    }

    public func execute(user: User, partner: Partner?, options: CourseOptions) async throws -> [CoursePlace] {
        var places = try await aiService.generateCoursePlan(user: user, partner: partner, options: options)
        var enriched: [CoursePlace] = []
        for place in places {
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
        return enriched
    }
}
