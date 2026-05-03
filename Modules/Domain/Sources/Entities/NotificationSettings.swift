import Foundation

public struct NotificationSettings: Codable, Equatable, Sendable {
    public var pushEnabled: Bool
    public var courseReminderEnabled: Bool
    public var anniversaryEnabled: Bool
    public var partnerEnabled: Bool

    public init(
        pushEnabled: Bool = true,
        courseReminderEnabled: Bool = true,
        anniversaryEnabled: Bool = true,
        partnerEnabled: Bool = true
    ) {
        self.pushEnabled = pushEnabled
        self.courseReminderEnabled = courseReminderEnabled
        self.anniversaryEnabled = anniversaryEnabled
        self.partnerEnabled = partnerEnabled
    }

    public static let `default` = NotificationSettings()
}

public enum NotificationPermissionStatus: Equatable, Sendable {
    case notDetermined
    case denied
    case authorized
}
