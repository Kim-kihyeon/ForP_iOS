import Foundation

public protocol PartnerRepositoryProtocol: Sendable {
    func fetchPartner(for userId: UUID) async throws -> Partner?
    func savePartner(_ partner: Partner) async throws
    func deletePartner(id: UUID) async throws
}
