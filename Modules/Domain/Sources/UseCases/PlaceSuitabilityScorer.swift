import Foundation

struct PlaceSuitabilityScorer {
    enum PlaceKind {
        case restaurant
        case cafe
        case bar
        case activity
        case any
    }

    enum RejectionReason: String {
        case missingPlaceId
        case duplicate
        case genericName
        case categoryMismatch
        case chainMismatch
        case fastFoodMismatch
        case foodTypeMismatch
        case repeatedLockedType
        case tooFar
    }

    struct Context {
        var baseLatitude: Double?
        var baseLongitude: Double?
        var usedPlaceIds: Set<String>
        var excludedKeys: Set<String>
        var lockedSpecificTypes: Set<String>
        var savedRecentPlaces: [CoursePlace]
        var recentlyGeneratedPlaces: [CoursePlace]

        init(
            baseLatitude: Double? = nil,
            baseLongitude: Double? = nil,
            usedPlaceIds: Set<String> = [],
            excludedKeys: Set<String> = [],
            lockedSpecificTypes: Set<String> = [],
            savedRecentPlaces: [CoursePlace] = [],
            recentlyGeneratedPlaces: [CoursePlace] = []
        ) {
            self.baseLatitude = baseLatitude
            self.baseLongitude = baseLongitude
            self.usedPlaceIds = usedPlaceIds
            self.excludedKeys = excludedKeys
            self.lockedSpecificTypes = lockedSpecificTypes
            self.savedRecentPlaces = savedRecentPlaces
            self.recentlyGeneratedPlaces = recentlyGeneratedPlaces
        }
    }

    struct Result {
        var score: Int
        var rejectionReason: RejectionReason?

        var isAccepted: Bool {
            rejectionReason == nil
        }
    }

    func evaluate(request: CoursePlace, candidate: CoursePlace, context: Context) -> Result {
        guard let id = candidate.kakaoPlaceId else {
            return Result(score: 0, rejectionReason: .missingPlaceId)
        }
        guard !context.usedPlaceIds.contains(id),
              !context.excludedKeys.contains(placeIdentityKey(candidate)) else {
            return Result(score: 0, rejectionReason: .duplicate)
        }
        guard passesBasicPlaceQuality(candidate) else {
            return Result(score: 0, rejectionReason: .genericName)
        }
        if let baseLat = context.baseLatitude, let baseLon = context.baseLongitude {
            guard isWithinPracticalDistance(candidate, baseLat: baseLat, baseLon: baseLon, request: request) else {
                return Result(score: 0, rejectionReason: .tooFar)
            }
        }
        guard isCategoryCompatible(generated: request, match: candidate) else {
            return Result(score: 0, rejectionReason: .categoryMismatch)
        }
        guard isChainAcceptable(generated: request, match: candidate) else {
            return Result(score: 0, rejectionReason: .chainMismatch)
        }
        guard isFastFoodAcceptable(generated: request, match: candidate) else {
            return Result(score: 0, rejectionReason: .fastFoodMismatch)
        }
        guard isSpecificFoodTypeCompatible(generated: request, match: candidate) else {
            return Result(score: 0, rejectionReason: .foodTypeMismatch)
        }

        let generatedType = specificFoodTypeKey(request)
        let matchedType = specificFoodTypeKey(candidate)
        if !context.lockedSpecificTypes.isEmpty {
            let repeatsLockedType = [generatedType, matchedType]
                .compactMap { $0 }
                .contains { context.lockedSpecificTypes.contains($0) }
            guard !repeatsLockedType else {
                return Result(score: 0, rejectionReason: .repeatedLockedType)
            }
        }

        let score = placeSuitabilityScore(
            candidate,
            baseLat: context.baseLatitude,
            baseLon: context.baseLongitude,
            request: request,
            context: context
        )
        return Result(score: score, rejectionReason: nil)
    }

    func rankCandidates(
        _ candidates: [CoursePlace],
        baseLat: Double,
        baseLon: Double,
        request: CoursePlace,
        context: Context
    ) -> [CoursePlace] {
        candidates
            .compactMap { candidate -> (CoursePlace, Int, Double)? in
                guard passesBasicPlaceQuality(candidate),
                      isWithinPracticalDistance(candidate, baseLat: baseLat, baseLon: baseLon, request: request) else {
                    return nil
                }
                let score = placeSuitabilityScore(
                    candidate,
                    baseLat: baseLat,
                    baseLon: baseLon,
                    request: request,
                    context: context
                )
                let distance = distanceMeters(fromLat: baseLat, lon: baseLon, to: candidate) ?? .greatestFiniteMagnitude
                return (candidate, score, distance)
            }
            .sorted { lhs, rhs in
                if lhs.1 != rhs.1 { return lhs.1 > rhs.1 }
                if lhs.2 != rhs.2 { return lhs.2 < rhs.2 }
                return (lhs.0.placeName ?? lhs.0.keyword).localizedStandardCompare(rhs.0.placeName ?? rhs.0.keyword) == .orderedAscending
            }
            .map(\.0)
    }

    func placeIdentityKey(_ place: CoursePlace) -> String {
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

    func specificFoodTypeKey(_ place: CoursePlace) -> String? {
        if let foodType = place.foodType, !foodType.isEmpty { return foodType }
        let text = [place.keyword, place.placeName]
            .compactMap { $0 }
            .joined(separator: " ")
            .lowercased()
        return foodTypeAliases.first { $0.keywords.contains { text.contains($0) } }?.type
    }

    func findFoodTypeAlias(for type: String) -> (type: String, keywords: [String])? {
        let n = type.lowercased()
        if let exact = foodTypeAliases.first(where: { $0.type.lowercased() == n }) { return exact }
        if let byKw = foodTypeAliases.first(where: { $0.keywords.contains { kw in n == kw || n.contains(kw) || kw.contains(n) } }) { return byKw }
        if let bySub = foodTypeAliases.first(where: { n.contains($0.type.lowercased()) || $0.type.lowercased().contains(n) }) { return bySub }
        return nil
    }

    var foodTypeAliases: [(type: String, keywords: [String])] {
        [
            ("훠궈", ["훠궈", "하이디라오", "haidilao", "hot pot", "hotpot"]),
            ("마라탕", ["마라탕"]),
            ("마라샹궈", ["마라샹궈"]),
            ("양꼬치", ["양꼬치"]),
            ("샤브샤브", ["샤브샤브"]),
            ("초밥", ["초밥", "스시", "sushi"]),
            ("사시미", ["사시미", "횟집", "회요리", "활어"]),
            ("오마카세", ["오마카세"]),
            ("라멘", ["라멘", "라면"]),
            ("우동", ["우동"]),
            ("돈카츠", ["돈카츠", "돈까스"]),
            ("이자카야", ["이자카야"]),
            ("파스타", ["파스타"]),
            ("피자", ["피자"]),
            ("스테이크", ["스테이크"]),
            ("리조또", ["리조또"]),
            ("와인바", ["와인바", "와인 바"]),
            ("막창", ["막창"]),
            ("대창", ["대창", "소대창"]),
            ("곱창", ["곱창"]),
            ("곱도리탕", ["곱도리탕"]),
            ("닭갈비", ["닭갈비"]),
            ("갈비탕", ["갈비탕"]),
            ("갈비", ["갈비"]),
            ("삼겹살", ["삼겹살"]),
            ("닭발", ["닭발"]),
            ("닭볶음탕", ["닭볶음탕", "닭도리탕"]),
            ("찜닭", ["찜닭"]),
            ("닭한마리", ["닭한마리"]),
            ("족발", ["족발"]),
            ("보쌈", ["보쌈"]),
            ("고깃집", ["고깃집", "고기집"]),
            ("꼼장어", ["꼼장어"]),
            ("장어", ["장어", "민물장어", "뱀장어"]),
            ("낙지", ["낙지"]),
            ("감자탕", ["감자탕"]),
            ("부대찌개", ["부대찌개"]),
            ("순대", ["순대"]),
            ("해장국", ["해장국"]),
            ("설렁탕", ["설렁탕"]),
            ("삼계탕", ["삼계탕"]),
            ("칼국수", ["칼국수"]),
            ("국밥", ["국밥"]),
            ("냉면", ["냉면"]),
            ("불고기", ["불고기"]),
            ("치킨", ["치킨"]),
            ("버거", ["버거", "햄버거"]),
            ("타코", ["타코"]),
            ("쌀국수", ["쌀국수"]),
            ("팟타이", ["팟타이"]),
            ("딤섬", ["딤섬"]),
            ("짜장면", ["짜장", "자장"]),
            ("짬뽕", ["짬뽕"]),
            ("떡볶이", ["떡볶이"]),
            ("브런치", ["브런치"]),
            ("베이커리", ["베이커리", "빵집"]),
            ("디저트", ["디저트", "케이크", "빙수"]),
        ]
    }

    func normalizedCategory(_ category: String) -> String {
        let lowercased = category.lowercased()
        if lowercased.contains("카페") { return "카페" }
        if lowercased.contains("브런치") { return "브런치" }
        if lowercased.contains("식") || lowercased.contains("맛집") || lowercased.contains("음식") { return "맛집" }
        if lowercased.contains("전시") || lowercased.contains("문화") { return "전시" }
        if lowercased.contains("공원") || lowercased.contains("산책") { return "공원" }
        if lowercased.contains("술") || lowercased.contains("바") { return "바" }
        return category.isEmpty ? "데이트" : category
    }

    func expectedPlaceKind(_ place: CoursePlace) -> PlaceKind {
        let text = searchableText(place)
        if text.contains("카페") || text.contains("디저트") || text.contains("브런치") || text.contains("베이커리") {
            return .cafe
        }
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

    func isFoodLike(_ place: CoursePlace) -> Bool {
        let text = searchableText(place)
        let foodSignals = [
            "맛집", "음식", "식당", "한식", "중식", "일식", "양식", "분식",
            "고기", "브런치", "디저트", "카페", "술집", "레스토랑",
            "파스타", "피자", "라멘", "초밥", "스시",
        ]
        return foodSignals.contains { text.contains($0) } || specificFoodTypeKey(place) != nil
    }

    func distanceMeters(fromLat lat: Double, lon: Double, to place: CoursePlace) -> Double? {
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

    private func searchableText(_ place: CoursePlace) -> String {
        [place.category, place.keyword, place.reason, place.menu]
            .compactMap { $0 }
            .joined(separator: " ")
            .lowercased()
    }

    private func passesBasicPlaceQuality(_ place: CoursePlace) -> Bool {
        let name = place.placeName ?? place.keyword
        guard !isGenericSearchLikePlaceName(name) else { return false }
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        return true
    }

    private func placeSuitabilityScore(
        _ place: CoursePlace,
        baseLat: Double?,
        baseLon: Double?,
        request: CoursePlace,
        context: Context
    ) -> Int {
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
        score += noveltyPenalty(for: place, request: request, context: context)

        if let baseLat, let baseLon,
           let distance = distanceMeters(fromLat: baseLat, lon: baseLon, to: place) {
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

    private func noveltyPenalty(for place: CoursePlace, request: CoursePlace, context: Context) -> Int {
        let key = placeIdentityKey(place)
        var penalty = 0

        if context.savedRecentPlaces.contains(where: { placeIdentityKey($0) == key }) {
            penalty -= 18
        }
        if context.recentlyGeneratedPlaces.contains(where: { placeIdentityKey($0) == key }) {
            penalty -= 10
        }

        if let candidateType = specificFoodTypeKey(place) ?? specificFoodTypeKey(request) {
            if context.savedRecentPlaces.contains(where: { specificFoodTypeKey($0) == candidateType }) {
                penalty -= 4
            }
            if context.recentlyGeneratedPlaces.contains(where: { specificFoodTypeKey($0) == candidateType }) {
                penalty -= 2
            }
        }

        return penalty
    }

    private func isWithinPracticalDistance(_ place: CoursePlace, baseLat: Double, baseLon: Double, request: CoursePlace) -> Bool {
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
            let genText = searchableText(generated)
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
        guard searchableText(generated).contains("브런치") else { return true }
        let matchedText = [match.placeName, match.category, match.keyword]
            .compactMap { $0 }
            .joined(separator: " ")
            .lowercased()
        return matchedText.contains("브런치") ||
            matchedText.contains("베이커리") ||
            matchedText.contains("레스토랑") ||
            matchedText.contains("양식") ||
            matchedText.contains("카페")
    }

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

    private func isChainAcceptable(generated: CoursePlace, match: CoursePlace) -> Bool {
        guard isChainCafe(match) else { return true }
        let text = searchableText(generated)
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
        let text = searchableText(generated)
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
}
