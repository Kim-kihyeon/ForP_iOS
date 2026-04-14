import Foundation

public struct FetchRecentCoursesUseCase {
    private let courseRepository: any CourseRepositoryProtocol

    public init(courseRepository: any CourseRepositoryProtocol) {
        self.courseRepository = courseRepository
    }

    public func execute(userId: UUID, limit: Int = 10) async throws -> [Course] {
        try await courseRepository.fetchRecentCourses(userId: userId, limit: limit)
    }
}
