import Foundation

public protocol UserRepositoryProtocol: Sendable {
    func fetchCurrentUser() async throws -> User
    func updateUser(_ user: User) async throws
}
