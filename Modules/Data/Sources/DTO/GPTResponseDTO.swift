import Foundation
import Domain

struct GPTResponseDTO: Decodable {
    let courses: [CoursePlaceDTO]

    struct CoursePlaceDTO: Decodable {
        let order: Int
        let category: String
        let keyword: String
        let reason: String
    }
}

extension GPTResponseDTO {
    func toDomain() -> [CoursePlace] {
        courses.map {
            CoursePlace(
                order: $0.order,
                category: $0.category,
                keyword: $0.keyword,
                reason: $0.reason
            )
        }
    }
}
