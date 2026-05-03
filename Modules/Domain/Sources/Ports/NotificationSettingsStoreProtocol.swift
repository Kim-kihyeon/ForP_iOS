import Foundation

public protocol NotificationSettingsStoreProtocol: Sendable {
    func load() -> NotificationSettings
    func save(_ settings: NotificationSettings)
    func saveFCMToken(_ token: String)
}
