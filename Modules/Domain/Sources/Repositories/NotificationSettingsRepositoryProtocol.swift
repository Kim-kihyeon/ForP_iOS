import Foundation

public protocol NotificationSettingsRepositoryProtocol: Sendable {
    func fetch(userId: UUID) async throws -> NotificationSettings
    func save(userId: UUID, settings: NotificationSettings) async throws
}
