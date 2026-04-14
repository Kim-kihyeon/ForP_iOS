import Foundation

final class GenerateCourseUseCase {
    func execute(user: User, partner: Partner?, options: CourseOptions) async throws -> [CoursePlace] {
        // TODO: GPTClient 호출 → keyword 배열 반환
        return []
    }
}

struct CourseOptions {
    var location: String
    var themes: [String]
    var placeCount: Int
    var mode: CourseMode
}
