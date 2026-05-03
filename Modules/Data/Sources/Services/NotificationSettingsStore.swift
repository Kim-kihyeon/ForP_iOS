import Foundation
import Domain

public struct NotificationSettingsStore: NotificationSettingsStoreProtocol, @unchecked Sendable {
    private let defaults: UserDefaults
    private let key = "forp.notificationSettings"
    private let fcmTokenKey = "forp.lastFCMToken"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load() -> NotificationSettings {
        guard let data = defaults.data(forKey: key),
              let settings = try? JSONDecoder().decode(NotificationSettings.self, from: data) else {
            return .default
        }
        return settings
    }

    public func save(_ settings: NotificationSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        defaults.set(data, forKey: key)
    }

    public func saveFCMToken(_ token: String) {
        defaults.set(token, forKey: fcmTokenKey)
    }
}
