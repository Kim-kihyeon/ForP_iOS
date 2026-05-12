import Foundation
import OSLog

public enum CourseGenerationError: LocalizedError {
    case invalidLocation(String)
    case noPlacesFound(String)
    case aiParsingFailed

    public var errorDescription: String? {
        switch self {
        case .invalidLocation(let location):
            return "'\(location)' 지역을 찾지 못했어요. 동네 이름을 조금 더 구체적으로 입력하거나, 검색 결과에서 지역을 선택해 주세요."
        case .noPlacesFound(let location):
            return "'\(location)' 주변에서 조건에 맞는 장소를 찾지 못했어요. 지역을 넓히거나 분위기/카테고리 조건을 줄여서 다시 시도해 주세요."
        case .aiParsingFailed:
            return "추천 결과를 정리하는 중 문제가 생겼어요. 같은 조건으로 다시 시도하거나, 조건을 조금 줄여서 생성해 주세요."
        }
    }
}

public struct GenerateCourseUseCase {
    private let aiService: any AIServiceProtocol
    private let placeRepository: any PlaceRepositoryProtocol
    private let weatherService: any WeatherServiceProtocol
    private let suitabilityScorer = PlaceSuitabilityScorer()
    private let compositionPolicy = CourseCompositionPolicy()
    private static let logger = Logger(subsystem: "com.forp.app", category: "CourseGeneration")

    public init(aiService: any AIServiceProtocol, placeRepository: any PlaceRepositoryProtocol, weatherService: any WeatherServiceProtocol) {
        self.aiService = aiService
        self.placeRepository = placeRepository
        self.weatherService = weatherService
    }

    public func execute(user: User, partner: Partner?, options: CourseOptions) async throws -> CoursePlan {
        Self.logger.info("Course generation started location=\(options.location, privacy: .private) themes=\(options.themes.joined(separator: ","), privacy: .private) requestedPlaces=\(options.placeCount) hasPartner=\(partner != nil)")

        // 좌표가 이미 확정된 경우(자동완성 선택) resolveLocation 스킵
        let resolved: (gptLocation: String, lat: Double, lon: Double)
        if let lat = options.baseLatitude, let lon = options.baseLongitude {
            resolved = (gptLocation: options.location, lat: lat, lon: lon)
        } else {
            guard let r = try await resolveLocation(options.location) else {
                Self.logger.error("Course generation failed invalid_location location=\(options.location, privacy: .private)")
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

        let rawPlan = try await aiService.generateCoursePlan(user: user, partner: partner, options: optionsWithWeather)
        let plan = filterPlanByMemoRestriction(rawPlan, memo: options.memo)
        Self.logger.info("AI course plan received selected=\(plan.places.count) candidates=\(plan.candidates.count) weather=\(optionsWithWeather.weatherDescription != nil)")
        // 이미 확보한 좌표 재사용 (re-geocode 불필요)
        let resolvedCoord = resolved

        // 선택된 장소 검증
        var enrichedSelected: [CoursePlace] = []
        var usedPlaceIds = Set(options.lockedPlaces.compactMap(\.kakaoPlaceId))
        let excludedKeys = Set((options.lockedPlaces + options.excludedPlaces).map(placeIdentityKey))
        // "X만" 제약이 있으면 X 타입은 lockedSpecificTypes에서 제외
        // (막창 고정 후 "막창만 추천" → 막창을 차단하면 안 됨)
        let memoConstraint = extractOnlyConstraint(from: options.memo)
        var lockedSpecificTypes = Set(options.lockedPlaces.compactMap(specificFoodTypeKey))
        if let c = memoConstraint {
            lockedSpecificTypes = lockedSpecificTypes.filter {
                !$0.lowercased().contains(c) && !c.contains($0.lowercased())
            }
        }
        var selectedSearchFailures = 0
        for place in plan.places {
            let results = await searchWithFallback(
                place: place,
                lat: resolvedCoord.lat,
                lon: resolvedCoord.lon,
                radius: options.searchRadius,
                options: options
            )
            if let match = results.first(where: { match in
                isAllowedReplacement(
                    generated: place,
                    match: match,
                    usedPlaceIds: usedPlaceIds,
                    excludedKeys: excludedKeys,
                    lockedSpecificTypes: lockedSpecificTypes
                )
            }),
               let name = match.placeName, let placeId = match.kakaoPlaceId {
                var updated = place
                updated.placeName = name
                updated.address = match.address
                updated.latitude = match.latitude
                updated.longitude = match.longitude
                updated.kakaoPlaceId = placeId
                updated.kakaoPlaceURL = match.kakaoPlaceURL
                if !match.category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    updated.category = match.category
                }
                updated.reason = verifiedReason(generated: place, match: match)
                updated.menu = nil
                enrichedSelected.append(updated)
                usedPlaceIds.insert(placeId)
            } else {
                selectedSearchFailures += 1
                Self.logger.warning("Selected place could not be verified keyword=\(place.keyword, privacy: .private) category=\(place.category, privacy: .private)")
            }
            if enrichedSelected.count == options.placeCount { break }
        }

        // 후보 장소 검증
        var enrichedCandidates: [CoursePlace] = []
        var candidateSearchFailures = 0
        for place in plan.candidates {
            let results = await searchWithFallback(
                place: place,
                lat: resolvedCoord.lat,
                lon: resolvedCoord.lon,
                radius: options.searchRadius,
                options: options
            )
            if let match = results.first(where: { match in
                isAllowedReplacement(
                    generated: place,
                    match: match,
                    usedPlaceIds: usedPlaceIds,
                    excludedKeys: excludedKeys,
                    lockedSpecificTypes: lockedSpecificTypes
                )
            }),
               let name = match.placeName, let placeId = match.kakaoPlaceId {
                var updated = place
                updated.placeName = name
                updated.address = match.address
                updated.latitude = match.latitude
                updated.longitude = match.longitude
                updated.kakaoPlaceId = placeId
                updated.kakaoPlaceURL = match.kakaoPlaceURL
                if !match.category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    updated.category = match.category
                }
                updated.reason = verifiedReason(generated: place, match: match)
                updated.menu = nil
                enrichedCandidates.append(updated)
                usedPlaceIds.insert(placeId)
            } else {
                candidateSearchFailures += 1
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
            Self.logger.error("Course generation failed no_places_found location=\(options.location, privacy: .private) selectedFailures=\(selectedSearchFailures) candidateFailures=\(candidateSearchFailures)")
            throw CourseGenerationError.noPlacesFound(options.location)
        }

        if memoConstraint == nil {
            let lockedKeys = Set(options.lockedPlaces.map(placeIdentityKey))
            let balanced = compositionPolicy.balance(
                selected: enrichedSelected,
                candidates: enrichedCandidates,
                lockedKeys: lockedKeys
            )
            enrichedSelected = balanced.selected
            enrichedCandidates = balanced.candidates
        }

        let reordered: [CoursePlace]
        if options.lockedPlaces.isEmpty {
            let optimized = nearestNeighborSort(enrichedSelected)
            reordered = optimized.enumerated().map { index, place -> CoursePlace in
                var p = place
                p.order = index + 1
                return p
            }
        } else {
            reordered = mergeLockedPlaces(
                locked: options.lockedPlaces,
                replacements: enrichedSelected + enrichedCandidates,
                totalCount: options.placeCount
            )
            enrichedCandidates.removeAll { candidate in
                reordered.contains { placeIdentityKey($0) == placeIdentityKey(candidate) }
            }
        }
        let reorderedCandidates = enrichedCandidates.enumerated().map { index, place -> CoursePlace in
            var p = place
            p.order = index + 1
            return p
        }
        Self.logger.info("Course generation completed selected=\(reordered.count) candidates=\(reorderedCandidates.count) selectedFailures=\(selectedSearchFailures) candidateFailures=\(candidateSearchFailures)")
        return CoursePlan(places: reordered, candidates: reorderedCandidates, outfitSuggestion: plan.outfitSuggestion, courseReason: plan.courseReason)
    }

    private func isAllowedReplacement(
        generated: CoursePlace,
        match: CoursePlace,
        usedPlaceIds: Set<String>,
        excludedKeys: Set<String>,
        lockedSpecificTypes: Set<String>
    ) -> Bool {
        suitabilityScorer.evaluate(
            request: generated,
            candidate: match,
            context: .init(
                usedPlaceIds: usedPlaceIds,
                excludedKeys: excludedKeys,
                lockedSpecificTypes: lockedSpecificTypes
            )
        ).isAccepted
    }

    private func eunNeun(_ word: String) -> String {
        guard let last = word.last else { return "은(는)" }
        let value = last.unicodeScalars.first!.value
        guard value >= 0xAC00, value <= 0xD7A3 else { return "은(는)" }
        return (value - 0xAC00) % 28 != 0 ? "은" : "는"
    }

    private func verifiedReason(generated: CoursePlace, match: CoursePlace) -> String {
        let matchedName = match.placeName ?? generated.keyword
        let p = eunNeun(matchedName)
        let specificType = specificFoodTypeKey(generated)

        if isChainCafe(match) {
            return "\(matchedName)\(p) 코스 중간에 잠깐 쉬어가기 좋은 카페예요."
        }

        if isBrunchRequest(generated), match.category.contains("음식점") && !match.category.contains("카페") {
            return "\(matchedName)\(p) 브런치나 가벼운 식사 흐름에 맞는 장소예요."
        }

        switch expectedPlaceKind(generated) {
        case .restaurant:
            if let type = specificType {
                let variants = [
                    "\(matchedName)\(p) \(type) 코스에 딱 맞는 장소예요.",
                    "\(type) 자리로 \(matchedName)\(p) 이 지역에서 찾은 선택이에요.",
                    "\(matchedName)\(p) \(type)을 즐기기에 좋은 장소라 코스에 넣었어요.",
                ]
                return variants.randomElement()!
            }
            let variants = [
                "\(matchedName)\(p) 코스 흐름에 잘 맞는 식사 장소예요.",
                "\(matchedName)\(p) 동선 안에서 찾은 이 지역 식사 장소예요.",
                "식사 자리로 \(matchedName)\(p) 코스에 자연스럽게 어울려요.",
            ]
            return variants.randomElement()!
        case .cafe:
            let variants = isBrunchRequest(generated)
                ? [
                    "\(matchedName)\(p) 브런치 코스 중간에 넣기 좋은 장소예요.",
                    "\(matchedName)\(p) 가볍게 먹고 쉬어가기 좋은 브런치 흐름이에요.",
                    "브런치 자리로 \(matchedName)\(p) 코스에 자연스럽게 어울려요.",
                ]
                : [
                    "\(matchedName)\(p) 코스 중간에 여유롭게 쉬어가기 좋은 카페예요.",
                    "\(matchedName)\(p) 대화하기 좋은 분위기라 코스에 넣었어요.",
                    "잠깐 앉아 이야기 나누기 좋은 \(matchedName)\(p) 코스 사이에 딱이에요.",
                ]
            return variants.randomElement()!
        case .bar:
            let variants = [
                "\(matchedName)\(p) 코스 마무리로 분위기 있게 머물기 좋아요.",
                "저녁 마지막으로 \(matchedName)\(p) 가볍게 한 잔 하기 좋은 장소예요.",
                "\(matchedName)\(p) 마무리 분위기를 살려줄 장소예요.",
            ]
            return variants.randomElement()!
        case .activity:
            let variants = [
                "\(matchedName)\(p) 식사 사이에 분위기를 바꿔줄 수 있어요.",
                "\(matchedName)\(p) 코스에 색다른 경험을 더해줄 장소예요.",
                "코스 중간에 \(matchedName)\(p) 넣으면 흐름이 살아나요.",
            ]
            return variants.randomElement()!
        case .any:
            let variants = [
                "\(matchedName)\(p) 이 지역 코스에 잘 어울리는 장소예요.",
                "\(matchedName)\(p) 동선과 분위기가 맞는 실제 장소예요.",
            ]
            return variants.randomElement()!
        }
    }

    // MARK: - Memo Restriction Filter

    /// memo에 "X만 추천/해줘" 패턴이 있으면 해당 타입이 아닌 GPT 생성 장소를 사전 제거.
    /// GPT가 프롬프트 규칙을 어겼을 때의 코드 레벨 안전망.
    private func filterPlanByMemoRestriction(_ plan: CoursePlan, memo: String) -> CoursePlan {
        guard let constraint = extractOnlyConstraint(from: memo) else { return plan }

        func isAllowed(_ place: CoursePlace) -> Bool {
            var words: [String] = [place.keyword.lowercased()]
            if let type = specificFoodTypeKey(place) {
                let aliasKeywords = findFoodTypeAlias(for: type)?.keywords ?? [type]
                words.append(contentsOf: aliasKeywords)
            }
            return words.contains { w in w.contains(constraint) || constraint.contains(w) }
        }

        return CoursePlan(
            places: plan.places.filter(isAllowed),
            candidates: plan.candidates.filter(isAllowed),
            outfitSuggestion: plan.outfitSuggestion,
            courseReason: plan.courseReason
        )
    }

    /// "막창집만 추천" → "막창", "용봉탕만 해줘" → "용봉탕" 추출.
    /// 1순위: "X만 추천/해줘/주세요/넣어줘" 명시 패턴 (오탐 가장 적음)
    /// 2순위: 알려진 alias 키워드 + "만" (동사 없이 "막창만"만 써도 감지, 오탐 방지를 위해 known type만)
    private func extractOnlyConstraint(from memo: String) -> String? {
        let suffixes = ["집만 추천", "만 추천", "집만 해줘", "만 해줘",
                        "집만 주세요", "만 주세요", "집만 넣어", "만 넣어", "집만"]
        for suffix in suffixes {
            guard let range = memo.range(of: suffix) else { continue }
            let word = String(memo[..<range.lowerBound])
                .components(separatedBy: .whitespacesAndNewlines)
                .last?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if word.count >= 2 { return word.lowercased() }
        }
        // 알려진 alias 키워드에 한해 bare "X만" 감지 ("강남만" 같은 위치 오탐 방지)
        let lowerMemo = memo.lowercased()
        for alias in foodTypeAliases {
            for kw in alias.keywords {
                let pattern = kw + "만"
                if lowerMemo == pattern || lowerMemo.hasSuffix(" " + pattern) ||
                   lowerMemo.hasSuffix("\n" + pattern) || lowerMemo.contains(pattern + " ") ||
                   lowerMemo.contains(pattern + "\n") {
                    return kw
                }
            }
        }
        return nil
    }

    private func mergeLockedPlaces(locked: [CoursePlace], replacements: [CoursePlace], totalCount: Int) -> [CoursePlace] {
        let lockedByOrder = Dictionary(uniqueKeysWithValues: locked.map { ($0.order, $0) })
        var replacementQueue = replacements
        var result: [CoursePlace] = []
        var usedKeys = Set(locked.map(placeIdentityKey))

        for order in 1...totalCount {
            if var lockedPlace = lockedByOrder[order] {
                lockedPlace.order = order
                lockedPlace.menu = nil
                result.append(lockedPlace)
                continue
            }

            guard let nextIndex = replacementQueue.firstIndex(where: { !usedKeys.contains(placeIdentityKey($0)) }) else {
                continue
            }
            var place = replacementQueue.remove(at: nextIndex)
            place.order = order
            usedKeys.insert(placeIdentityKey(place))
            result.append(place)
        }

        return result.sorted { $0.order < $1.order }
    }

    private func placeIdentityKey(_ place: CoursePlace) -> String {
        suitabilityScorer.placeIdentityKey(place)
    }

    // GPT가 명시한 foodType 우선, 없으면 keyword에서만 추론 (reason 제외 — false positive 방지)
    private func specificFoodTypeKey(_ place: CoursePlace) -> String? {
        suitabilityScorer.specificFoodTypeKey(place)
    }

    /// foodType 문자열로 alias를 찾음. 정확한 type 매치 → keyword 포함 여부 → 부분 문자열 순으로 시도.
    /// GPT가 "막창집", "스시"처럼 alias type과 다르게 내려줄 때도 올바른 alias를 찾을 수 있게 함.
    private func findFoodTypeAlias(for type: String) -> (type: String, keywords: [String])? {
        suitabilityScorer.findFoodTypeAlias(for: type)
    }

    // foodType → 카카오 검색 fallback 키워드 매핑 (타입 감지 목적 아님)
    private var foodTypeAliases: [(type: String, keywords: [String])] {
        suitabilityScorer.foodTypeAliases
    }

    // 지역 입력 파싱: 단일 지역은 그대로, 복합 표현은 중간점 계산
    // gptLocation: GPT 프롬프트/키워드에 사용할 단순 지명
    private func searchWithFallback(place: CoursePlace, lat: Double, lon: Double, radius: Int, options: CourseOptions) async -> [CoursePlace] {
        let keywords = fallbackKeywords(for: place)
        let firstTier = await searchCandidatePool(keywords: keywords, lat: lat, lon: lon, radius: radius)
        let firstRanked = rankedCourseCandidates(firstTier, baseLat: lat, baseLon: lon, request: place, options: options)
        if !firstRanked.isEmpty { return firstRanked }

        let secondTierRadius = min(max(radius * 2, 3_000), isFoodLike(place) ? 3_500 : 8_000)
        let secondTier = await searchCandidatePool(keywords: keywords, lat: lat, lon: lon, radius: secondTierRadius)
        let secondRanked = rankedCourseCandidates(secondTier, baseLat: lat, baseLon: lon, request: place, options: options)
        if !secondRanked.isEmpty { return secondRanked }

        guard !isFoodLike(place) else { return [] }

        // 비음식 활동만 넓게 확장한다. 음식점은 멀리 있는 애매한 후보보다 실패가 낫다.
        let finalTier = await searchCandidatePool(keywords: keywords, lat: lat, lon: lon, radius: 12_000)
        return rankedCourseCandidates(finalTier, baseLat: lat, baseLon: lon, request: place, options: options)
    }

    private func searchCandidatePool(keywords: [String], lat: Double, lon: Double, radius: Int) async -> [CoursePlace] {
        var seen = Set<String>()
        var pool: [CoursePlace] = []
        for keyword in keywords {
            let results = (try? await placeRepository.searchPlaces(keyword: keyword, latitude: lat, longitude: lon, radius: radius)) ?? []
            for place in results {
                let key = placeIdentityKey(place)
                guard seen.insert(key).inserted else { continue }
                pool.append(place)
            }
        }
        return pool
    }

    private func fallbackKeywords(for place: CoursePlace) -> [String] {
        let location = place.keyword
            .components(separatedBy: .whitespacesAndNewlines).first ?? place.keyword

        // 특정 음식 유형 확인 (foodType 우선, 없으면 keyword 추론)
        // "막창"이면 fallback도 막창 키워드만, 범용 키워드로 절대 확장하지 않음.
        if let foodType = specificFoodTypeKey(place),
           let alias = findFoodTypeAlias(for: foodType) {
            var keywords: [String] = [place.keyword]
            for kw in alias.keywords.prefix(3) {
                let candidate = "\(location) \(kw)"
                if candidate != place.keyword { keywords.append(candidate) }
            }
            var seen = Set<String>()
            return keywords
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty && seen.insert($0).inserted }
        }

        // 카페/디저트/브런치/베이커리 계열 — 카페 범주 안에서만 fallback
        let text = [place.category, place.keyword, place.reason, place.menu]
            .compactMap { $0 }.joined(separator: " ").lowercased()
        let isCafeLike = text.contains("카페") || text.contains("디저트") ||
                         text.contains("브런치") || text.contains("베이커리")
        if isCafeLike {
            var seen = Set<String>()
            return [place.keyword, "\(location) 카페", "\(location) 디저트 카페"]
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty && seen.insert($0).inserted }
        }

        // 일반 음식점 (특정 유형 없음) — 카테고리 수준 fallback만 허용
        let category = normalizedCategory(place.category)
        if isFoodLike(place) {
            var seen = Set<String>()
            return [
                place.keyword,
                category == "맛집" ? "\(location) 음식점" : "\(location) \(category)",
                "\(location) 음식점",
            ]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && seen.insert($0).inserted }
        }

        // 활동/전시 등 비음식 장소
        var seen = Set<String>()
        return [place.keyword, "\(location) \(category)", "\(location) 데이트", location]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && seen.insert($0).inserted }
    }

    private func rankedCourseCandidates(
        _ places: [CoursePlace],
        baseLat: Double,
        baseLon: Double,
        request: CoursePlace,
        options: CourseOptions
    ) -> [CoursePlace] {
        suitabilityScorer.rankCandidates(
            places,
            baseLat: baseLat,
            baseLon: baseLon,
            request: request,
            context: .init(
                baseLatitude: baseLat,
                baseLongitude: baseLon,
                savedRecentPlaces: options.savedRecentPlaces,
                recentlyGeneratedPlaces: options.recentlyGeneratedPlaces
            )
        )
    }

    private func passesBasicPlaceQuality(_ place: CoursePlace) -> Bool {
        let name = place.placeName ?? place.keyword
        guard !isGenericSearchLikePlaceName(name) else { return false }
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        return true
    }

    private func placeQualityScore(_ place: CoursePlace, baseLat: Double, baseLon: Double, request: CoursePlace) -> Int {
        let name = place.placeName ?? place.keyword
        let category = place.category
        var score = 0

        score += min(category.components(separatedBy: ">").count, 4)
        if category.contains("음식점") || category.contains("카페") { score += 2 }
        if name.count >= 3 { score += 2 }
        if name.count >= 5 { score += 1 }
        if name.contains("본점") || name.contains("직영") { score += 1 }
        if isGenericSearchLikePlaceName(name) { score -= 10 }
        if category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { score -= 2 }
        if category.contains("기타") { score -= 2 }
        if isChainCafe(place) { score -= 5 }
        if isFastFoodChain(place) { score -= 4 }
        if let distance = distanceMeters(fromLat: baseLat, lon: baseLon, to: place) {
            switch distance {
            case ..<800:
                score += 5
            case ..<1_500:
                score += 3
            case ..<2_500:
                score += 1
            case ..<3_500:
                score -= isFoodLike(request) ? 4 : 1
            case ..<5_000:
                score -= isFoodLike(request) ? 8 : 3
            default:
                score -= isFoodLike(request) ? 14 : 6
            }
        }
        return score
    }

    private func isWithinPracticalDistance(
        _ place: CoursePlace,
        baseLat: Double,
        baseLon: Double,
        request: CoursePlace
    ) -> Bool {
        guard let distance = distanceMeters(fromLat: baseLat, lon: baseLon, to: place) else { return true }
        if isFoodLike(request) {
            return distance <= (isSpecificFoodTypeScarce(request) ? 4_500 : 3_500)
        }
        switch expectedPlaceKind(request) {
        case .activity:
            return distance <= 10_000
        case .bar:
            return distance <= 4_500
        case .cafe, .restaurant:
            return distance <= 3_500
        case .any:
            return distance <= 6_000
        }
    }

    private func isSpecificFoodTypeScarce(_ place: CoursePlace) -> Bool {
        guard let type = specificFoodTypeKey(place) else { return false }
        let scarceTypes = [
            "오마카세", "사시미", "훠궈", "마라샹궈", "양꼬치", "딤섬",
            "꼼장어", "장어", "닭한마리", "곱도리탕", "와인바",
        ]
        return scarceTypes.contains(type)
    }

    private func isCategoryCompatible(generated: CoursePlace, match: CoursePlace) -> Bool {
        guard isSpecificCafeCompatible(generated: generated, match: match) else { return false }
        let expected = expectedPlaceKind(generated)
        guard expected != .any else { return true }
        let category = match.category
        switch expected {
        case .restaurant:
            return category.contains("음식점")
        case .cafe:
            if category.contains("카페") { return true }
            // 브런치 요청은 카카오에서 "음식점 > 양식" 등으로 분류될 수 있어 음식점 카테고리도 허용
            let genText = [generated.category, generated.keyword, generated.reason, generated.menu]
                .compactMap { $0 }.joined(separator: " ").lowercased()
            return genText.contains("브런치") && category.contains("음식점")
        case .bar:
            return category.contains("술집") || category.contains("주점")
        case .activity:
            return !category.contains("음식점") && !category.contains("카페")
        case .any:
            return true
        }
    }

    private func isSpecificCafeCompatible(generated: CoursePlace, match: CoursePlace) -> Bool {
        let generatedText = [
            generated.category,
            generated.keyword,
            generated.reason,
            generated.menu,
        ]
        .compactMap { $0 }
        .joined(separator: " ")
        .lowercased()

        guard generatedText.contains("브런치") else { return true }

        let matchedText = [
            match.placeName,
            match.category,
            match.keyword,
        ]
        .compactMap { $0 }
        .joined(separator: " ")
        .lowercased()

        return matchedText.contains("브런치") ||
            matchedText.contains("베이커리") ||
            matchedText.contains("레스토랑") ||
            matchedText.contains("양식") ||
            matchedText.contains("카페")
    }

    /// GPT가 지정한 음식 유형과 매칭 장소의 유형이 일치해야 함.
    /// - genType: foodType 우선, 없으면 keyword 추론 (specificFoodTypeKey)
    /// - matchText: Kakao placeName·category만 — match.keyword는 우리가 보낸 검색어라 항상 일치해 의미 없음
    private func isSpecificFoodTypeCompatible(generated: CoursePlace, match: CoursePlace) -> Bool {
        guard let genType = specificFoodTypeKey(generated) else { return true }
        let matchText = [match.placeName, match.category]
            .compactMap { $0 }
            .joined(separator: " ")
            .lowercased()
        if genType == "브런치" {
            return ["브런치", "베이커리", "레스토랑", "양식", "카페"].contains { matchText.contains($0) }
        }
        let keywords = findFoodTypeAlias(for: genType)?.keywords ?? [genType]
        return keywords.contains { matchText.contains($0) }
    }

    private func isBrunchRequest(_ place: CoursePlace) -> Bool {
        [place.foodType, place.category, place.keyword, place.reason, place.menu]
            .compactMap { $0 }
            .joined(separator: " ")
            .lowercased()
            .contains("브런치")
    }

    private func isChainAcceptable(generated: CoursePlace, match: CoursePlace) -> Bool {
        guard isChainCafe(match) else { return true }

        let text = [
            generated.category,
            generated.keyword,
            generated.reason,
            generated.menu,
        ]
        .compactMap { $0 }
        .joined(separator: " ")
        .lowercased()

        let requiresLocalMood = [
            "브런치", "감성", "트렌디", "분위기", "데이트", "디저트",
            "로스터리", "베이커리", "대화", "오붓",
            "와인", "로맨틱", "특별한", "힐링", "아늑", "야경", "루프탑",
            "핸드드립", "스페셜티", "싱글오리진",
        ].contains { text.contains($0) }
        if requiresLocalMood { return false }

        let allowsSimpleCafe = [
            "커피", "카페", "휴식", "가볍", "잠깐", "저렴", "가성비",
            "테이크아웃",
        ].contains { text.contains($0) }
        return allowsSimpleCafe
    }

    private func isFastFoodAcceptable(generated: CoursePlace, match: CoursePlace) -> Bool {
        guard isFastFoodChain(match) else { return true }

        let text = [
            generated.category,
            generated.keyword,
            generated.reason,
            generated.menu,
        ]
        .compactMap { $0 }
        .joined(separator: " ")
        .lowercased()

        let allowsQuickMeal = [
            "가성비", "간단", "빠르게", "가볍", "테이크아웃", "햄버거", "버거",
        ].contains { text.contains($0) }
        let requiresDateMood = [
            "데이트", "감성", "트렌디", "오붓", "분위기", "특별", "로맨틱",
            "브런치", "디저트", "대화",
        ].contains { text.contains($0) }

        return allowsQuickMeal && !requiresDateMood
    }

    private func isChainCafe(_ place: CoursePlace) -> Bool {
        let name = place.placeName ?? place.keyword
        let chainKeywords = [
            "메가커피", "메가MGC커피", "컴포즈커피", "빽다방", "이디야", "스타벅스",
            "투썸플레이스", "할리스", "커피빈", "폴바셋", "엔제리너스", "파스쿠찌",
            "공차", "더벤티", "매머드커피", "커피에반하다", "커피베이", "탐앤탐스",
            "요거프레소", "하삼동커피", "텐퍼센트커피",
        ]
        return chainKeywords.contains { name.localizedCaseInsensitiveContains($0) }
    }

    // 패스트푸드/베이커리 체인 — 데이트 코스에 어울리지 않는 장소 감점용
    private func isFastFoodChain(_ place: CoursePlace) -> Bool {
        let name = place.placeName ?? place.keyword
        let keywords = [
            "맥도날드", "KFC", "케이에프씨", "롯데리아", "버거킹", "맘스터치",
            "파파이스", "노브랜드버거", "서브웨이",
            "파리바게뜨", "뚜레쥬르", "베스킨라빈스", "배스킨라빈스", "던킨도너츠", "던킨",
            "한솥도시락",
        ]
        return keywords.contains { name.localizedCaseInsensitiveContains($0) }
    }

    private enum ExpectedPlaceKind {
        case restaurant
        case cafe
        case bar
        case activity
        case any
    }

    private func expectedPlaceKind(_ place: CoursePlace) -> ExpectedPlaceKind {
        let text = [
            place.category,
            place.keyword,
            place.reason,
            place.menu,
        ]
        .compactMap { $0 }
        .joined(separator: " ")
        .lowercased()

        if text.contains("카페") || text.contains("디저트") || text.contains("브런치") || text.contains("베이커리") {
            return .cafe
        }
        // "바"는 파스타바/주스바/샐러드바 등 false positive가 있어 제거
        // 명확한 술집 신호어만 사용
        let barSignals = [
            "술집", "와인바", "와인 바", "칵테일바", "칵테일 바", "이자카야",
            "호프", "맥주집", "펍", "포차", "주점", "소주바", "라운지바",
        ]
        if barSignals.contains(where: { text.contains($0) }) {
            return .bar
        }
        if isFoodLike(place) {
            return .restaurant
        }
        if text.contains("전시") || text.contains("문화") || text.contains("공원") || text.contains("산책") || text.contains("영화") {
            return .activity
        }
        return .any
    }

    private func isFoodLike(_ place: CoursePlace) -> Bool {
        let text = [
            place.category,
            place.keyword,
            place.reason,
            place.menu,
        ]
        .compactMap { $0 }
        .joined(separator: " ")
        .lowercased()

        let foodSignals = [
            "맛집", "음식", "식당", "한식", "중식", "일식", "양식", "분식",
            "고기", "브런치", "디저트", "카페", "술집", "레스토랑",
            "파스타", "피자", "라멘", "초밥", "스시",
            // "바" 제거: 파스타바/주스바 등 food가 아닌 케이스 포함될 수 있음
            // 와인바/이자카야 등은 specificFoodTypeKey에서 처리됨
        ]
        return foodSignals.contains { text.contains($0) } || specificFoodTypeKey(place) != nil
    }

    private func isGenericSearchLikePlaceName(_ name: String) -> Bool {
        let normalized = name
            .folding(options: [.caseInsensitive, .widthInsensitive], locale: .current)
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()
            .lowercased()

        let genericNames: Set<String> = [
            "맛집", "한식맛집", "중식맛집", "일식맛집", "양식맛집", "고기맛집",
            "카페맛집", "데이트맛집", "브런치맛집", "디저트맛집", "술집맛집",
            "맛집추천", "한식", "중식", "일식", "양식", "분식", "음식점",
            "카페", "브런치", "디저트", "술집", "밥집",
        ]
        if genericNames.contains(normalized) { return true }

        let genericSuffixes = ["맛집", "추천", "데이트"]
        let genericPrefixes = ["한식", "중식", "일식", "양식", "고기", "카페", "브런치", "디저트", "술집", "밥집"]
        return genericPrefixes.contains { prefix in
            genericSuffixes.contains { suffix in
                normalized == "\(prefix)\(suffix)"
            }
        }
    }

    private func normalizedCategory(_ category: String) -> String {
        let lowercased = category.lowercased()
        if lowercased.contains("카페") { return "카페" }
        if lowercased.contains("브런치") { return "브런치" }
        if lowercased.contains("식") || lowercased.contains("맛집") || lowercased.contains("음식") { return "맛집" }
        if lowercased.contains("전시") || lowercased.contains("문화") { return "전시" }
        if lowercased.contains("공원") || lowercased.contains("산책") { return "공원" }
        if lowercased.contains("술") || lowercased.contains("바") { return "바" }
        return category.isEmpty ? "데이트" : category
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

    private func distanceMeters(fromLat lat: Double, lon: Double, to place: CoursePlace) -> Double? {
        guard let placeLat = place.latitude, let placeLon = place.longitude else { return nil }
        let dlat = (placeLat - lat) * .pi / 180
        let dlon = (placeLon - lon) * .pi / 180
        let lat1 = lat * .pi / 180
        let lat2 = placeLat * .pi / 180
        let a = sin(dlat / 2) * sin(dlat / 2) +
            cos(lat1) * cos(lat2) * sin(dlon / 2) * sin(dlon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return 6_371_000 * c
    }
}

private struct CourseCompositionPolicy {
    enum Role: Equatable {
        case meal
        case cafeDessert
        case bar
        case activity
        case other
    }

    func balance(
        selected: [CoursePlace],
        candidates: [CoursePlace],
        lockedKeys: Set<String>
    ) -> (selected: [CoursePlace], candidates: [CoursePlace]) {
        guard selected.count >= 2 else { return (selected, candidates) }

        let selectedRoles = selected.map(role)
        guard shouldRebalance(roles: selectedRoles) else { return (selected, candidates) }

        let dominantRole = dominantRole(in: selectedRoles)
        let preferredRoles = preferredReplacementRoles(for: dominantRole)
        guard let candidateIndex = candidates.firstIndex(where: { preferredRoles.contains(role(for: $0)) }) else {
            return (selected, candidates)
        }
        guard let replaceIndex = selected.indices.reversed().first(where: { index in
            role(for: selected[index]) == dominantRole &&
            !lockedKeys.contains(identityKey(selected[index]))
        }) else {
            return (selected, candidates)
        }

        var nextSelected = selected
        var nextCandidates = candidates
        let replacement = nextCandidates.remove(at: candidateIndex)
        var removed = nextSelected[replaceIndex]
        var updatedReplacement = replacement
        updatedReplacement.order = removed.order
        removed.order = replacement.order
        nextSelected[replaceIndex] = updatedReplacement
        nextCandidates.insert(removed, at: candidateIndex)

        return (nextSelected, nextCandidates)
    }

    private func shouldRebalance(roles: [Role]) -> Bool {
        let meaningfulRoles = roles.filter { $0 != .other }
        guard meaningfulRoles.count >= 2 else { return false }
        let counts = Dictionary(grouping: meaningfulRoles, by: { $0 }).mapValues(\.count)
        if roles.count == 2 {
            return counts[.meal, default: 0] == 2 || counts[.cafeDessert, default: 0] == 2
        }
        return counts[.meal, default: 0] >= roles.count ||
            counts[.cafeDessert, default: 0] >= roles.count ||
            counts.values.contains { $0 >= 3 }
    }

    private func dominantRole(in roles: [Role]) -> Role {
        Dictionary(grouping: roles, by: { $0 })
            .max { lhs, rhs in lhs.value.count < rhs.value.count }?
            .key ?? .other
    }

    private func preferredReplacementRoles(for dominantRole: Role) -> [Role] {
        switch dominantRole {
        case .meal:
            return [.cafeDessert, .activity, .bar, .other]
        case .cafeDessert:
            return [.meal, .activity, .bar, .other]
        case .bar:
            return [.meal, .cafeDessert, .activity, .other]
        case .activity:
            return [.meal, .cafeDessert, .bar, .other]
        case .other:
            return [.meal, .cafeDessert, .activity, .bar]
        }
    }

    private func role(for place: CoursePlace) -> Role {
        let text = [
            place.foodType,
            place.category,
            place.keyword,
            place.placeName,
            place.reason,
        ]
        .compactMap { $0 }
        .joined(separator: " ")
        .lowercased()

        let barSignals = ["술집", "와인바", "와인 바", "칵테일", "이자카야", "펍", "포차", "주점", "맥주"]
        if barSignals.contains(where: { text.contains($0) }) { return .bar }

        let cafeSignals = ["카페", "디저트", "브런치", "베이커리", "케이크", "빙수", "로스터리", "커피"]
        if cafeSignals.contains(where: { text.contains($0) }) { return .cafeDessert }

        let activitySignals = ["전시", "문화", "공원", "산책", "영화", "소품샵", "쇼핑", "서점", "공방", "체험"]
        if activitySignals.contains(where: { text.contains($0) }) { return .activity }

        let mealSignals = [
            "음식점", "맛집", "식당", "한식", "중식", "일식", "양식", "분식",
            "레스토랑", "파스타", "피자", "라멘", "초밥", "스시", "고기",
            "막창", "곱창", "삼겹살", "훠궈", "마라탕", "샤브샤브", "국밥",
        ]
        if mealSignals.contains(where: { text.contains($0) }) { return .meal }

        return .other
    }

    private func identityKey(_ place: CoursePlace) -> String {
        if let id = place.kakaoPlaceId, !id.isEmpty {
            return "id:\(id)"
        }
        let name = (place.placeName ?? place.keyword)
            .folding(options: [.caseInsensitive, .widthInsensitive], locale: .current)
            .components(separatedBy: .whitespacesAndNewlines)
            .joined()
        let address = (place.address ?? "")
            .folding(options: [.caseInsensitive, .widthInsensitive], locale: .current)
            .components(separatedBy: .whitespacesAndNewlines)
            .joined()
        return "text:\(name)|\(address)"
    }
}
