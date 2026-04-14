import Foundation

public protocol NotificationServiceProtocol: Sendable {
    func requestPermission() async -> Bool
    func scheduleAnniversaryNotifications(for anniversaries: [Anniversary]) async
}
