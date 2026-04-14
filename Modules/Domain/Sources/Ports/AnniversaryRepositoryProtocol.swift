import Foundation

public protocol AnniversaryRepositoryProtocol: Sendable {
    func fetchAnniversaries(userId: UUID) async throws -> [Anniversary]
    func saveAnniversary(_ anniversary: Anniversary) async throws
    func deleteAnniversary(id: UUID) async throws
}
