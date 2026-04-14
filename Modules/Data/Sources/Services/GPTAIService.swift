import Foundation
import Moya
import Domain

public struct GPTAIService: AIServiceProtocol {
    private let provider: MoyaProvider<GPTTarget>

    public init(provider: MoyaProvider<GPTTarget>) {
        self.provider = provider
    }

    public func generateCoursePlan(user: User, partner: Partner?, options: CourseOptions) async throws -> [CoursePlace] {
        let prompt = buildPrompt(user: user, partner: partner, options: options)
        return try await withCheckedThrowingContinuation { continuation in
            provider.request(.generateCourse(prompt: prompt)) { result in
                switch result {
                case .success(let response):
                    do {
                        let dto = try JSONDecoder().decode(GPTResponseDTO.self, from: response.data)
                        continuation.resume(returning: dto.toDomain())
                    } catch {
                        continuation.resume(throwing: error)
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func buildPrompt(user: User, partner: Partner?, options: CourseOptions) -> String {
        var prompt = """
        데이트 코스를 JSON으로 추천해줘.
        위치: \(options.location)
        테마: \(options.themes.joined(separator: ", "))
        장소 수: \(options.placeCount)
        내 선호: \(user.preferredCategories.joined(separator: ", "))
        내 비선호: \(user.dislikedCategories.joined(separator: ", "))
        """
        if let partner {
            prompt += """

            파트너 선호: \(partner.preferredCategories.joined(separator: ", "))
            파트너 비선호: \(partner.dislikedCategories.joined(separator: ", "))
            파트너 메모: \(partner.notes)
            """
        }
        prompt += """

        응답 형식:
        {"courses": [{"order": 1, "category": "카페", "keyword": "감성 카페 홍대", "reason": "이유"}]}
        """
        return prompt
    }
}
