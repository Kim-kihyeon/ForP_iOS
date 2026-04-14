import Foundation

public struct SaveCourseUseCase {
    private let courseRepository: any CourseRepositoryProtocol

    public init(courseRepository: any CourseRepositoryProtocol) {
        self.courseRepository = courseRepository
    }

    public func execute(_ course: Course) async throws {
        try await courseRepository.saveCourse(course)
    }
}
