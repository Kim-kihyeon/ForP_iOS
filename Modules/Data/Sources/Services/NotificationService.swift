import Foundation
import UserNotifications
import Domain

public struct NotificationService: NotificationServiceProtocol {
    public init() {}

    public func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    public func scheduleAnniversaryNotifications(for anniversaries: [Anniversary]) async {
        let center = UNUserNotificationCenter.current()
        // 기존 기념일 알림 전부 제거 후 재등록
        let pending = await center.pendingNotificationRequests()
        let ids = pending.filter { $0.identifier.hasPrefix("anniversary-") }.map { $0.identifier }
        center.removePendingNotificationRequests(withIdentifiers: ids)

        for anniversary in anniversaries {
            schedule(anniversary, daysBefore: 30, center: center)
            schedule(anniversary, daysBefore: 7, center: center)
            schedule(anniversary, daysBefore: 0, center: center)
        }
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
