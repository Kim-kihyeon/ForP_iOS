import Foundation

public enum CourseGenerationError: LocalizedError {
    case invalidLocation(String)
    case noPlacesFound(String)
    case aiParsingFailed

    public var errorDescription: String? {
        switch self {
        case .invalidLocation(let location):
            return "'\(location)'을 찾을 수 없어요. 올바른 지역명을 입력해주세요. (예: 강남, 홍대, 성수동)"
        case .noPlacesFound(let location):
            return "'\(location)' 주변에서 조건에 맞는 장소를 찾지 못했어요. 다른 테마나 지역으로 다시 시도해보세요."
        case .aiParsingFailed:
            return "코스 생성 중 오류가 발생했어요. 다시 시도해주세요."
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
        // 좌표가 이미 확정된 경우(자동완성 선택) resolveLocation 스킵
        let resolved: (gptLocation: String, lat: Double, lon: Double)
        if let lat = options.baseLatitude, let lon = options.baseLongitude {
            resolved = (gptLocation: options.location, lat: lat, lon: lon)
        } else {
            guard let r = try await resolveLocation(options.location) else {
                throw CourseGenerationError.invalidLocation(options.location)
            }
            resolved = r
        }
        var options = options
        options.location = resolved.gptLocation

        // 위치 좌표 조회 → 날씨 조회
        var optionsWithWeather = options
        if let weather = try? await weatherService.fetchWeather(latitude: resolved.lat, longitude: resolved.lon, date: options.date) {
            optionsWithWeather.weatherDescription = weather.description
        }

        let plan = try await aiService.generateCoursePlan(user: user, partner: partner, options: optionsWithWeather)
        // 이미 확보한 좌표 재사용 (re-geocode 불필요)
        let resolvedCoord = resolved

        // 선택된 장소 검증
        var enrichedSelected: [CoursePlace] = []
        var usedPlaceIds: Set<String> = []
        for place in plan.places {
            let results = await searchWithFallback(place: place, lat: resolvedCoord.lat, lon: resolvedCoord.lon, radius: options.searchRadius)
            if let first = results.first, let name = first.placeName, let placeId = first.kakaoPlaceId, !usedPlaceIds.contains(placeId) {
                var updated = place
                updated.placeName = name
                updated.address = first.address
                updated.latitude = first.latitude
                updated.longitude = first.longitude
                updated.kakaoPlaceId = placeId
                enrichedSelected.append(updated)
                usedPlaceIds.insert(placeId)
            }
            if enrichedSelected.count == options.placeCount { break }
        }

        // 후보 장소 검증
        var enrichedCandidates: [CoursePlace] = []
        for place in plan.candidates {
            let results = await searchWithFallback(place: place, lat: resolvedCoord.lat, lon: resolvedCoord.lon, radius: options.searchRadius)
            if let first = results.first, let name = first.placeName, let placeId = first.kakaoPlaceId, !usedPlaceIds.contains(placeId) {
                var updated = place
                updated.placeName = name
                updated.address = first.address
                updated.latitude = first.latitude
                updated.longitude = first.longitude
                updated.kakaoPlaceId = placeId
                enrichedCandidates.append(updated)
                usedPlaceIds.insert(placeId)
            }
        }

        // 선택 장소가 부족하면 후보에서 보충
        if enrichedSelected.count < options.placeCount {
            let needed = options.placeCount - enrichedSelected.count
            let fill = Array(enrichedCandidates.prefix(needed))
            enrichedCandidates = Array(enrichedCandidates.dropFirst(needed))
            enrichedSelected.append(contentsOf: fill)
        }

        guard !enrichedSelected.isEmpty else {
            throw CourseGenerationError.noPlacesFound(options.location)
        }

        let optimized = nearestNeighborSort(enrichedSelected)
        let reordered = optimized.enumerated().map { index, place -> CoursePlace in
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

    // 지역 입력 파싱: 단일 지역은 그대로, 복합 표현은 중간점 계산
    // gptLocation: GPT 프롬프트/키워드에 사용할 단순 지명
    private func searchWithFallback(place: CoursePlace, lat: Double, lon: Double, radius: Int) async -> [CoursePlace] {
        // 1차: 반경 검색
        let radiusResults = (try? await placeRepository.searchPlaces(keyword: place.keyword, latitude: lat, longitude: lon, radius: radius)) ?? []
        if !radiusResults.isEmpty { return radiusResults }

        // 2차: 반경 2배 확장
        let widerResults = (try? await placeRepository.searchPlaces(keyword: place.keyword, latitude: lat, longitude: lon, radius: radius * 2)) ?? []
        if !widerResults.isEmpty { return widerResults }

        // 3차: 최대 반경(20km)으로 확장 검색 — 필터 유지
        return (try? await placeRepository.searchPlaces(keyword: place.keyword, latitude: lat, longitude: lon, radius: 20_000)) ?? []
    }

    private func resolveLocation(_ input: String) async throws -> (gptLocation: String, lat: Double, lon: Double)? {
        // 1. 단순 지역명이면 바로 반환
        let isValid = (try? await placeRepository.isValidKoreanRegion(keyword: input)) ?? false
        if isValid, let place = try? await placeRepository.searchPlaces(keyword: input).first,
           let lat = place.latitude, let lon = place.longitude {
            return (gptLocation: input, lat: lat, lon: lon)
        }

        // 2. 복합 입력 분리 시도
        let separators = ["와", "과", "사이", "에서", "~", "&", ",", "·"]
        var parts: [String] = []
        for sep in separators {
            if input.contains(sep) {
                parts = input.components(separatedBy: sep)
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty && $0.count >= 2 }
                if parts.count >= 2 { break }
            }
        }
        guard parts.count >= 2 else { return nil }

        // 3. 각 파트 geocode
        var coords: [(Double, Double)] = []
        var validParts: [String] = []
        for part in parts.prefix(3) {
            if let place = try? await placeRepository.searchPlaces(keyword: part).first,
               let lat = place.latitude, let lon = place.longitude {
                coords.append((lat, lon))
                validParts.append(part)
            }
        }
        guard !coords.isEmpty else { return nil }

        // 4. 중간점 계산, GPT에는 첫 번째 유효 지명만 전달 (키워드 prefix로 사용)
        let midLat = coords.map { $0.0 }.reduce(0, +) / Double(coords.count)
        let midLon = coords.map { $0.1 }.reduce(0, +) / Double(coords.count)
        return (gptLocation: validParts[0], lat: midLat, lon: midLon)
    }

    private func nearestNeighborSort(_ places: [CoursePlace]) -> [CoursePlace] {
        guard places.count > 2 else { return places }
        let hasCoords = places.filter { $0.latitude != nil && $0.longitude != nil }
        guard hasCoords.count == places.count else { return places }

        var remaining = places
        var sorted: [CoursePlace] = [remaining.removeFirst()]

        while !remaining.isEmpty {
            let last = sorted.last!
            let nearestIdx = remaining.indices.min { i, j in
                coord_dist(last, remaining[i]) < coord_dist(last, remaining[j])
            }!
            sorted.append(remaining.remove(at: nearestIdx))
        }
        return sorted
    }

    private func coord_dist(_ a: CoursePlace, _ b: CoursePlace) -> Double {
        let dlat = (a.latitude ?? 0) - (b.latitude ?? 0)
        let dlon = (a.longitude ?? 0) - (b.longitude ?? 0)
        return dlat * dlat + dlon * dlon
    }
}
