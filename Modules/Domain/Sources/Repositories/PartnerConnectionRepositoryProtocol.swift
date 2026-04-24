import Foundation

public protocol PartnerConnectionRepositoryProtocol: Sendable {
    func getOrCreateMyCode(userId: UUID) async throws -> String
    func connect(code: String, myUserId: UUID) async throws -> PartnerConnection
    func fetchConnection(userId: UUID) async throws -> PartnerConnection?
    func fetchUser(id: UUID) async throws -> Domain.User
    func disconnect(connectionId: UUID) async throws
}
