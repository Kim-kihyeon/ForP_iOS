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
        5. keyword는 반드시 2~3단어 이내로 짧게 작성하세요. (예: "강남역 카페" O, "강남역 분위기 좋은 루프탑 카페" X)
        6. placeCount의 2배 장소를 생성하되, 가장 좋은 placeCount개에만 "isSelected": true를 표시하세요.
        7. courseReason: 이 코스를 추천하는 이유를 2-3문장으로 설명하세요.
        8. 동선은 반드시 지리적으로 인접한 장소끼리 이동하도록 order를 배치하세요. 불필요하게 먼 곳을 오가는 동선은 절대 만들지 마세요.
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
        테마: \(options.themes.isEmpty ? "자유" : options.themes.joined(separator: ", "))
        선호 테마: \(user.preferredThemes.isEmpty ? "없음" : user.preferredThemes.joined(separator: ", "))
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
        - menu: 이 카테고리에서 일반적으로 즐기는 음식 종류나 활동 (예: "파스타, 와인", "아메리카노, 디저트"). 실제 존재하는 메뉴를 확신할 수 없으면 카테고리 특성 기반의 일반적인 표현으로만 작성. 카페·음식점·브런치·술/바 외에는 null
        - outfit: 날씨·코스 분위기에 맞는 옷차림 제안 1-2문장
        - isSelected: 최종 코스 포함 시 true, 후보 장소는 false
        """
        return prompt
    }
}
