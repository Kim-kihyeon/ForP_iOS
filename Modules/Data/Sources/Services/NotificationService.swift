import Foundation
import UserNotifications
import Domain

public struct NotificationService: NotificationServiceProtocol {
    public init() {}

    public func permissionStatus() async -> NotificationPermissionStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:
            return .notDetermined
        case .denied:
            return .denied
        case .authorized, .provisional, .ephemeral:
            return .authorized
        @unknown default:
            return .denied
        }
    }

    public func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    public func scheduleCourseNotification(for course: Course) async {
        let center = UNUserNotificationCenter.current()
        let id = "course-\(course.id)"
        center.removePendingNotificationRequests(withIdentifiers: [id])

        let calendar = Calendar.current
        let courseDay = calendar.startOfDay(for: course.date)
        guard courseDay >= calendar.startOfDay(for: Date()) else { return }

        let content = UNMutableNotificationContent()
        content.title = "오늘 데이트 어때요?"
        content.body = "\(course.title) 코스, 오늘 즐겨보세요!"
        content.sound = .default

        var components = calendar.dateComponents([.year, .month, .day], from: course.date)
        components.hour = 8
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        try? await center.add(request)
    }

    public func cancelCourseNotification(courseId: UUID) async {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["course-\(courseId)"])
    }

    public func cancelCourseNotifications() async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let ids = pending.filter { $0.identifier.hasPrefix("course-") }.map { $0.identifier }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    public func scheduleAnniversaryNotifications(for anniversaries: [Anniversary]) async {
        let center = UNUserNotificationCenter.current()
        // 기존 기념일 알림 전부 제거 후 재등록
        await cancelAnniversaryNotifications()

        for anniversary in anniversaries {
            schedule(anniversary, daysBefore: 30, center: center)
            schedule(anniversary, daysBefore: 7, center: center)
            schedule(anniversary, daysBefore: 0, center: center)
        }
    }

    public func cancelAnniversaryNotifications() async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let ids = pending.filter { $0.identifier.hasPrefix("anniversary-") }.map { $0.identifier }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    private func schedule(_ anniversary: Anniversary, daysBefore: Int, center: UNUserNotificationCenter) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        var components = calendar.dateComponents([.month, .day], from: anniversary.date)
        components.year = calendar.component(.year, from: today)
        guard var target = calendar.date(from: components) else { return }
        if target < today { target = calendar.date(byAdding: .year, value: 1, to: target)! }
        guard let notifyDate = calendar.date(byAdding: .day, value: -daysBefore, to: target),
              notifyDate >= today else { return }

        let content = UNMutableNotificationContent()
        content.sound = .default

        let years = calendar.dateComponents([.year], from: anniversary.date, to: target).year ?? 0
        let yearText = years > 0 ? " \(years)주년" : ""

        if daysBefore == 0 {
            content.title = "오늘은 기념일이에요!"
            content.body = "오늘은 \(anniversary.name)\(yearText)이에요."
        } else {
            content.title = "기념일이 다가와요"
            content.body = "\(daysBefore)일 후 \(anniversary.name)\(yearText)이에요."
        }

        var triggerComponents = calendar.dateComponents([.year, .month, .day], from: notifyDate)
        triggerComponents.hour = 9
        triggerComponents.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)

        let id = "anniversary-\(anniversary.id)-\(daysBefore)"
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request)
    }
}
