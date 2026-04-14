import Foundation

public protocol CourseRepositoryProtocol: Sendable {
    func fetchRecentCourses(userId: UUID, limit: Int) async throws -> [Course]
    func saveCourse(_ course: Course) async throws
    func deleteCourse(id: UUID) async throws
}
