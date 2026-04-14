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
    private let weatherService: any WeatherServiceProtocol

    public init(aiService: any AIServiceProtocol, placeRepository: any PlaceRepositoryProtocol, weatherService: any WeatherServiceProtocol) {
        self.aiService = aiService
        self.placeRepository = placeRepository
        self.weatherService = weatherService
    }

    public func execute(user: User, partner: Partner?, options: CourseOptions) async throws -> CoursePlan {
        let isValid = try await placeRepository.isValidKoreanRegion(keyword: options.location)
        guard isValid else {
            throw CourseGenerationError.invalidLocation(options.location)
        }

        // 위치 좌표 조회 → 날씨 조회
        var optionsWithWeather = options
        if let coord = try? await placeRepository.searchPlaces(keyword: options.location).first,
           let lat = coord.latitude, let lon = coord.longitude,
           let weather = try? await weatherService.fetchWeather(latitude: lat, longitude: lon, date: options.date) {
            optionsWithWeather.weatherDescription = weather.description
        }

        let plan = try await aiService.generateCoursePlan(user: user, partner: partner, options: optionsWithWeather)
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
