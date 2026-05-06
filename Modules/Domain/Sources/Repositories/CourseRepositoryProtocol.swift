import Foundation

public protocol CourseRepositoryProtocol: Sendable {
    func fetchCourse(id: UUID) async throws -> Course
    func fetchRecentCourses(userId: UUID, limit: Int) async throws -> [Course]
    func fetchInProgressCourse(userId: UUID) async throws -> Course?
    func fetchCoursesByMonth(userId: UUID, year: Int, month: Int) async throws -> [Course]
    func saveCourse(_ course: Course) async throws
    func deleteCourse(id: UUID) async throws
    func toggleLike(id: UUID, isLiked: Bool) async throws
    func startCourse(id: UUID, userId: UUID, visitedOrders: [Int]) async throws
    func updateVisitedOrders(id: UUID, visitedOrders: [Int]) async throws
    func updateRating(id: UUID, rating: Int, review: String) async throws
    func updatePartnerRating(id: UUID, rating: Int, review: String) async throws
    func updateTitle(id: UUID, title: String) async throws
    func endCourse(id: UUID) async throws
    func cancelCourse(id: UUID) async throws
    func observeIsEnded(courseId: UUID) -> AsyncStream<Void>
    func notifyPartner(courseId: UUID) async
}
