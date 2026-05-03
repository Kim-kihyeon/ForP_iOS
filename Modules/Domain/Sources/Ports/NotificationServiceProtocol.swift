import Foundation

public protocol NotificationServiceProtocol: Sendable {
    func permissionStatus() async -> NotificationPermissionStatus
    func requestPermission() async -> Bool
    func scheduleAnniversaryNotifications(for anniversaries: [Anniversary]) async
    func cancelAnniversaryNotifications() async
    func scheduleCourseNotification(for course: Course) async
    func cancelCourseNotification(courseId: UUID) async
    func cancelCourseNotifications() async
}
