import Foundation
import Domain

// GPT API 실제 응답 구조
struct GPTAPIResponse: Decodable {
    let choices: [Choice]

    struct Choice: Decodable {
        let message: Message

        struct Message: Decodable {
            let content: String
        }
    }
}

// content 안의 JSON 구조
struct GPTResponseDTO: Decodable {
    let courses: [CoursePlaceDTO]
    let outfit: String

    struct CoursePlaceDTO: Decodable {
        let order: Int
        let category: String
        let keyword: String
        let reason: String
        let menu: String?
    }
}

extension GPTAPIResponse {
    func toCoursePlan() throws -> CoursePlan {
        guard let content = choices.first?.message.content else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "choices가 비어있습니다."))
        }
        let data = Data(content.utf8)
        let dto = try JSONDecoder().decode(GPTResponseDTO.self, from: data)
        let places = dto.courses.map {
            CoursePlace(
                order: $0.order,
                category: $0.category,
                keyword: $0.keyword,
                reason: $0.reason,
                menu: $0.menu
            )
        }
        return CoursePlan(places: places, outfitSuggestion: dto.outfit)
    }
}
