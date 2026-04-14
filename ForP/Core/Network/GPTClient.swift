import Foundation

final class GPTClient {
    static let shared = GPTClient()
    private init() {}

    // TODO: GPT-4o API 호출 구현
    func generateCourse(prompt: String) async throws -> [CoursePlace] {
        return []
    }
}
