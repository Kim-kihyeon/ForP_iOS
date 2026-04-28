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
    let courseReason: String
    let courses: [CoursePlaceDTO]
    let outfit: String

    struct CoursePlaceDTO: Decodable {
        let order: Int
        let category: String
        let keyword: String
        let reason: String
        let menu: String?
        let isSelected: Bool
    }
}

extension GPTAPIResponse {
    func toCoursePlan() throws -> CoursePlan {
        guard let content = choices.first?.message.content else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "choices가 비어있습니다."))
        }
        // markdown 코드블록 제거 후 순수 JSON만 추출
        let jsonString: String
        if let start = content.firstIndex(of: "{"), let end = content.lastIndex(of: "}") {
            jsonString = String(content[start...end])
        } else {
            jsonString = content
        }
        let data = Data(jsonString.utf8)
        guard let dto = try? JSONDecoder().decode(GPTResponseDTO.self, from: data) else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "GPT 응답 파싱 실패"))
        }
        guard !dto.courses.isEmpty else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "courses가 비어있습니다."))
        }
        let selected = dto.courses.filter { $0.isSelected }.map {
            CoursePlace(order: $0.order, category: $0.category, keyword: $0.keyword, reason: $0.reason, menu: $0.menu)
        }
        let candidates = dto.courses.filter { !$0.isSelected }.map {
            CoursePlace(order: $0.order, category: $0.category, keyword: $0.keyword, reason: $0.reason, menu: $0.menu)
        }
        return CoursePlan(places: selected, candidates: candidates, outfitSuggestion: dto.outfit, courseReason: dto.courseReason)
    }
}
