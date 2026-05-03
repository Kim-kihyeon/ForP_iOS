import Foundation
import Supabase
import Domain

public final class NotificationSettingsRepository: NotificationSettingsRepositoryProtocol {
    private let supabase: SupabaseClient

    public init(supabase: SupabaseClient) {
        self.supabase = supabase
    }

    public func fetch(userId: UUID) async throws -> NotificationSettings {
        let row: NotificationSettingsRow = try await supabase
            .from("notification_preferences")
            .select()
            .eq("user_id", value: userId)
            .single()
            .execute()
            .value
        return row.toDomain()
    }

    public func save(userId: UUID, settings: NotificationSettings) async throws {
        let row = NotificationSettingsRow(userId: userId, settings: settings)
        try await supabase
            .from("notification_preferences")
            .upsert(row)
            .execute()
    }
}

private struct NotificationSettingsRow: Codable {
    let userId: UUID
    let pushEnabled: Bool
    let courseReminderEnabled: Bool
    let anniversaryEnabled: Bool
    let partnerEnabled: Bool

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case pushEnabled = "push_enabled"
        case courseReminderEnabled = "course_reminder_enabled"
        case anniversaryEnabled = "anniversary_enabled"
        case partnerEnabled = "partner_enabled"
    }

    init(userId: UUID, settings: NotificationSettings) {
        self.userId = userId
        self.pushEnabled = settings.pushEnabled
        self.courseReminderEnabled = settings.courseReminderEnabled
        self.anniversaryEnabled = settings.anniversaryEnabled
        self.partnerEnabled = settings.partnerEnabled
    }

    func toDomain() -> NotificationSettings {
        NotificationSettings(
            pushEnabled: pushEnabled,
            courseReminderEnabled: courseReminderEnabled,
            anniversaryEnabled: anniversaryEnabled,
            partnerEnabled: partnerEnabled
        )
    }
}
