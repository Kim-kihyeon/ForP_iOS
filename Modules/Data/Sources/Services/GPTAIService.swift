import Foundation
import Supabase
import Domain

public struct GPTAIService: AIServiceProtocol {
    private let supabase: SupabaseClient

    public init(supabase: SupabaseClient) {
        self.supabase = supabase
    }

    public func generateCoursePlan(user: Domain.User, partner: Partner?, options: CourseOptions) async throws -> CoursePlan {
        let systemMessage = buildSystemMessage(location: options.location)
        let prompt = buildPrompt(user: user, partner: partner, options: options)
        let apiResponse: GPTAPIResponse = try await supabase.functions.invoke(
            "generate-course",
            options: .init(body: GenerateCourseRequest(systemMessage: systemMessage, prompt: prompt))
        )
        return try apiResponse.toCoursePlan()
    }

    private struct GenerateCourseRequest: Encodable {
        let systemMessage: String
        let prompt: String
    }

    private func buildSystemMessage(location: String) -> String {
        let locations = location.components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        let isMultiple = locations.count > 1
        let locationConstraint = isMultiple ? "[\(location)] 중 하나의 반경" : "'\(location)' 반경"
        let keywordConstraint = isMultiple ? "[\(location)] 중 하나로 시작하는" : "'\(location)'으로 시작하는"
        let keywordExamples = locations.prefix(2).map { "\"\($0) 카페\"" }.joined(separator: " 또는 ")
        return """
        당신은 한국 커플 데이트 코스 큐레이터입니다.

        절대 규칙:
        1. 모든 장소는 \(locationConstraint)에 실제로 존재해야 합니다.
        2. 지정된 지역과 무관한 다른 동/구의 장소는 단 하나도 포함할 수 없습니다.
        3. keyword 값은 반드시 \(keywordConstraint) 카카오맵 검색어여야 합니다.
           올바른 예: \(keywordExamples)
           잘못된 예: 지역명 없는 키워드, 지정 지역이 아닌 다른 지역명으로 시작하는 키워드
        4. 실제 카카오맵에서 검색 가능한 장소만 추천하세요. 지하철역, 버스터미널, 아파트, 빌라, 주차장, 주유소, 은행, 편의점, 공공기관, 병원, 약국, 학원, 장례식장, 대형마트, 부동산은 절대 포함하지 마세요.
        5. 카페·브런치·식당은 로컬 매장, 감성 공간, 대화하기 좋은 분위기, 디저트/메뉴 개성이 있는 곳을 우선 추천하세요.
        6. 동네 특색이 약한 대형 프랜차이즈/저가 체인 카페는 우선순위를 낮추세요. 단, 해당 지역에 적절한 로컬 후보가 부족하면 프랜차이즈라도 실제로 이용하기 좋은 곳을 추천할 수 있습니다.
        7. keyword는 반드시 2~3단어 이내로 짧게 작성하세요. (예: "강남역 카페" O, "강남역 분위기 좋은 루프탑 카페" X)
        8. placeCount의 2배 장소를 생성하되, 가장 좋은 placeCount개에만 "isSelected": true를 표시하세요.
        9. courseReason: 이 코스를 추천하는 이유를 2-3문장으로 설명하세요.
        10. 동선은 반드시 지리적으로 인접한 장소끼리 이동하도록 order를 배치하세요. 불필요하게 먼 곳을 오가는 동선은 절대 만들지 마세요.
        11. 고정 장소가 주어진 경우 같은 장소를 새 장소로 다시 추천하지 말고, 고정 장소와 잘 이어지는 대체 장소만 추천하세요.
        12. 제외 장소가 주어진 경우 동일한 장소명, 같은 지점, 같은 브랜드의 같은 지점은 절대 추천하지 마세요.
        13. 고정 장소와 같은 세부 음식/활동 유형을 반복하지 마세요. 예: 고정 장소가 훠궈집이면 다른 훠궈집을 추천하지 말고, 이자카야·파스타·전시·카페처럼 성격이 다른 장소로 바꾸세요.
        """
    }

    private func buildPrompt(user: Domain.User, partner: Partner?, options: CourseOptions) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ko_KR")
        dateFormatter.dateFormat = "M월 d일 (E)"
        let dateString = dateFormatter.string(from: options.date)

        var prompt = """
        지역: \(options.location) (이 지역 장소만 추천)
        날짜: \(dateString)
        날씨: \(options.weatherDescription ?? "정보 없음")
        장소 수: 총 \(options.placeCount * 2)개 생성, 그 중 \(options.placeCount)개 선택 (isSelected: true)
        이번 코스 분위기: \(options.themes.isEmpty ? "자유" : options.themes.joined(separator: ", "))
        기본 선호 분위기: \(user.preferredThemes.isEmpty ? "없음" : user.preferredThemes.joined(separator: ", "))
        내 선호: \(user.preferredCategories.isEmpty ? "없음" : user.preferredCategories.joined(separator: ", "))
        내 비선호: \(user.dislikedCategories.isEmpty ? "없음" : user.dislikedCategories.joined(separator: ", "))
        절대 제외 (내): \(user.foodBlacklist.isEmpty ? "없음" : user.foodBlacklist.joined(separator: ", "))
        """
        if !options.memo.isEmpty {
            prompt += "\n요청사항 (최우선 반영): \(options.memo)"
        }
        if !options.wishlistPlaces.isEmpty {
            let names = options.wishlistPlaces.map { $0.placeName ?? $0.keyword }.joined(separator: ", ")
            prompt += "\n선호 장소 (가능하면 포함, 단 \(options.location) 지역이 아닌 경우 비슷한 유형으로 대체): \(names)"
        }
        if !options.lockedPlaces.isEmpty {
            let locked = options.lockedPlaces
                .sorted { $0.order < $1.order }
                .map { "\($0.order)번 \($0.placeName ?? $0.keyword)" }
                .joined(separator: ", ")
            prompt += "\n고정 장소 (이미 선택됨, 같은 장소를 새 추천에 중복 포함 금지): \(locked)"
            prompt += "\n고정 장소의 앞뒤 동선과 카테고리 균형을 고려해서 나머지 자리만 대체하세요."
            let lockedTypes = Set(options.lockedPlaces.compactMap(specificFoodTypeKey)).sorted()
            if !lockedTypes.isEmpty {
                prompt += "\n고정 장소와 겹치면 안 되는 세부 유형: \(lockedTypes.joined(separator: ", "))"
                prompt += "\n위 세부 유형은 새 추천과 후보 장소 모두에서 제외하세요. 같은 음식 종류의 다른 매장도 금지입니다."
            }
        }
        if !options.excludedPlaces.isEmpty {
            let excluded = options.excludedPlaces
                .map { $0.placeName ?? $0.keyword }
                .joined(separator: ", ")
            prompt += "\n이번에 제외할 기존 장소 (다시 추천 금지): \(excluded)"
        }
        if let partner, !partner.nickname.isEmpty {
            prompt += """

            파트너(\(partner.nickname)) 선호: \(partner.preferredCategories.isEmpty ? "없음" : partner.preferredCategories.joined(separator: ", "))
            파트너 비선호: \(partner.dislikedCategories.isEmpty ? "없음" : partner.dislikedCategories.joined(separator: ", "))
            절대 제외 (파트너): \(partner.foodBlacklist.isEmpty ? "없음" : partner.foodBlacklist.joined(separator: ", "))
            """
            if !partner.notes.isEmpty {
                prompt += "\n파트너 특이사항: \(partner.notes)"
            }
        }
        prompt += "\n생성 seed: \(Int(Date().timeIntervalSince1970) % 100000)"
        prompt += """

        필드 안내:
        - keyword: '\(options.location)'으로 시작하는 카카오맵 검색어 (예: "\(options.location) 감성 카페")
        - 카페/브런치/음식점 keyword는 프랜차이즈명보다 지역+분위기/카테고리 조합을 우선 사용 (예: "\(options.location) 로스터리", "\(options.location) 디저트 카페")
        - menu: 실제 매장의 대표메뉴를 확인할 수 없으므로 항상 null
        - outfit: 날씨·코스 분위기에 맞는 옷차림 제안 1-2문장
        - isSelected: 최종 코스 포함 시 true, 후보 장소는 false
        """
        return prompt
    }

    private func specificFoodTypeKey(_ place: CoursePlace) -> String? {
        let text = [
            place.placeName,
            place.keyword,
            place.category,
            place.menu,
            place.reason,
        ]
        .compactMap { $0 }
        .joined(separator: " ")
        .lowercased()

        let aliases: [(type: String, keywords: [String])] = [
            ("훠궈", ["훠궈", "하이디라오", "haidilao", "hot pot", "hotpot"]),
            ("마라탕", ["마라탕"]),
            ("마라샹궈", ["마라샹궈"]),
            ("양꼬치", ["양꼬치"]),
            ("샤브샤브", ["샤브샤브"]),
            ("초밥", ["초밥", "스시", "sushi"]),
            ("사시미", ["사시미", "회"]),
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
            ("삼겹살", ["삼겹살"]),
            ("고깃집", ["고깃집", "고기집", "구이"]),
            ("갈비", ["갈비"]),
            ("곱창", ["곱창"]),
            ("막창", ["막창"]),
            ("족발", ["족발"]),
            ("보쌈", ["보쌈"]),
            ("곱도리탕", ["곱도리탕"]),
            ("닭갈비", ["닭갈비"]),
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

        return aliases.first { alias in
            alias.keywords.contains { text.contains($0) }
        }?.type
    }
}
