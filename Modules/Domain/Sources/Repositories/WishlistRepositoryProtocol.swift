import Foundation

public protocol WishlistRepositoryProtocol: Sendable {
    func fetchAll(userId: UUID) async throws -> [WishlistPlace]
    func save(_ place: WishlistPlace) async throws
    func delete(id: UUID) async throws
}
