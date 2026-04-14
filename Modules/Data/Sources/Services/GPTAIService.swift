import Foundation
@preconcurrency import Moya
import Domain

public struct GPTAIService: AIServiceProtocol {
    private let provider: MoyaProvider<GPTTarget>

    public init(provider: MoyaProvider<GPTTarget>) {
        self.provider = provider
    }

    public func generateCoursePlan(user: User, partner: Partner?, options: CourseOptions) async throws -> CoursePlan {
        let systemMessage = buildSystemMessage(location: options.location)
        let prompt = buildPrompt(user: user, partner: partner, options: options)
        return try await withCheckedThrowingContinuation { continuation in
            provider.request(.generateCourse(systemMessage: systemMessage, prompt: prompt)) { result in
                switch result {
                case .success(let response):
                    do {
                        let apiResponse = try JSONDecoder().decode(GPTAPIResponse.self, from: response.data)
                        continuation.resume(returning: try apiResponse.toCoursePlan())
                    } catch {
                        continuation.resume(throwing: error)
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func buildSystemMessage(location: String) -> String {
        return """
        당신은 한국 커플 데이트 코스 큐레이터입니다.
        반드시 유효한 JSON만 출력하세요. 설명, 마크다운, 추가 텍스트 없이 JSON만.

        절대 규칙 (위반 시 응답 무효):
        1. 모든 장소는 '\(location)'에 실제로 존재해야 합니다.
        2. '\(location)'이 아닌 다른 시/구/동의 장소는 단 하나도 포함할 수 없습니다.
        3. keyword 값은 반드시 '\(location)'으로 시작하는 카카오맵 검색어여야 합니다.
           올바른 예: "\(location) 카페", "\(location) 이탈리안 레스토랑"
           잘못된 예: "홍대 카페", "부산 맛집", 지역명 없는 키워드
        4. 실제 카카오맵에서 검색 가능한 장소만 추천하세요.
        """
    }

    private func buildPrompt(user: User, partner: Partner?, options: CourseOptions) -> String {
        var prompt = """
        지역: \(options.location) (이 지역 장소만 추천)
        장소 수: \(options.placeCount)개
        테마: \(options.themes.isEmpty ? "자유" : options.themes.joined(separator: ", "))
        내 선호: \(user.preferredCategories.isEmpty ? "없음" : user.preferredCategories.joined(separator: ", "))
        내 비선호: \(user.dislikedCategories.isEmpty ? "없음" : user.dislikedCategories.joined(separator: ", "))
        """
        if let partner, !partner.nickname.isEmpty {
            prompt += """

            파트너(\(partner.nickname)) 선호: \(partner.preferredCategories.isEmpty ? "없음" : partner.preferredCategories.joined(separator: ", "))
            파트너 비선호: \(partner.dislikedCategories.isEmpty ? "없음" : partner.dislikedCategories.joined(separator: ", "))
            """
            if !partner.notes.isEmpty {
                prompt += "\n파트너 특이사항: \(partner.notes)"
            }
        }
        prompt += """

        응답 형식 (JSON만, 예시):
        {
          "courses": [
            {
              "order": 1,
              "category": "카페",
              "keyword": "\(options.location) 감성 카페",
              "reason": "조용한 분위기에서 대화하기 좋은 곳",
              "menu": "아인슈페너, 크루아상"
            },
            {
              "order": 2,
              "category": "음식점",
              "keyword": "\(options.location) 파스타",
              "reason": "분위기 좋은 이탈리안 레스토랑",
              "menu": "트러플 파스타, 티라미수"
            }
          ],
          "outfit": "가벼운 재킷에 청바지 조합이 어울려요. 저녁엔 쌀쌀할 수 있으니 얇은 겉옷을 챙기세요."
        }

        규칙:
        - menu: 해당 장소에서 추천하는 메뉴 또는 즐길 거리 (카페/음식점은 반드시 포함, 그 외는 null 가능)
        - outfit: 오늘 코스와 날씨/분위기에 어울리는 옷차림 제안 (1-2문장)
        """
        return prompt
    }
}
