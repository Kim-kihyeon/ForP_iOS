import Foundation

public protocol AIServiceProtocol: Sendable {
    func generateCoursePlan(user: User, partner: Partner?, options: CourseOptions) async throws -> [CoursePlace]
}
