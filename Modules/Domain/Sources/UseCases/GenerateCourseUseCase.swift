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
        let locationCoord = try? await placeRepository.searchPlaces(keyword: options.location).first

        // 선택된 장소 검증
        var enrichedSelected: [CoursePlace] = []
        var usedPlaceNames: Set<String> = []
        for place in plan.places {
            let results: [CoursePlace]
            if let lat = locationCoord?.latitude, let lon = locationCoord?.longitude {
                results = (try? await placeRepository.searchPlaces(keyword: place.keyword, latitude: lat, longitude: lon, radius: 5000)) ?? []
            } else {
                results = (try? await placeRepository.searchPlaces(keyword: place.keyword)) ?? []
            }
            if let first = results.first, let name = first.placeName, !usedPlaceNames.contains(name) {
                var updated = place
                updated.placeName = name
                updated.address = first.address
                updated.latitude = first.latitude
                updated.longitude = first.longitude
                enrichedSelected.append(updated)
                usedPlaceNames.insert(name)
            }
            if enrichedSelected.count == options.placeCount { break }
        }

        // 후보 장소 검증
        var enrichedCandidates: [CoursePlace] = []
        for place in plan.candidates {
            let results: [CoursePlace]
            if let lat = locationCoord?.latitude, let lon = locationCoord?.longitude {
                results = (try? await placeRepository.searchPlaces(keyword: place.keyword, latitude: lat, longitude: lon, radius: 5000)) ?? []
            } else {
                results = (try? await placeRepository.searchPlaces(keyword: place.keyword)) ?? []
            }
            if let first = results.first, let name = first.placeName, !usedPlaceNames.contains(name) {
                var updated = place
                updated.placeName = name
                updated.address = first.address
                updated.latitude = first.latitude
                updated.longitude = first.longitude
                enrichedCandidates.append(updated)
                usedPlaceNames.insert(name)
            }
        }

        // 선택 장소가 부족하면 후보에서 보충
        if enrichedSelected.count < options.placeCount {
            let needed = options.placeCount - enrichedSelected.count
            let fill = Array(enrichedCandidates.prefix(needed))
            enrichedCandidates = Array(enrichedCandidates.dropFirst(needed))
            enrichedSelected.append(contentsOf: fill)
        }

        let reordered = enrichedSelected.enumerated().map { index, place -> CoursePlace in
            var p = place
            p.order = index + 1
            return p
        }
        let reorderedCandidates = enrichedCandidates.enumerated().map { index, place -> CoursePlace in
            var p = place
            p.order = index + 1
            return p
        }
        return CoursePlan(places: reordered, candidates: reorderedCandidates, outfitSuggestion: plan.outfitSuggestion, courseReason: plan.courseReason)
    }
}
