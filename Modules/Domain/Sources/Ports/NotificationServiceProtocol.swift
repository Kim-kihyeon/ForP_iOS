import Foundation

public protocol NotificationServiceProtocol: Sendable {
    func requestPermission() async -> Bool
    func scheduleAnniversaryNotifications(for anniversaries: [Anniversary]) async
    func scheduleCourseNotification(for course: Course) async
    func cancelCourseNotification(courseId: UUID) async
}
