import Foundation

public protocol AuthRepositoryProtocol: Sendable {
    func loginWithKakao() async throws -> User
    func loginWithApple(idToken: String, nonce: String) async throws -> User
    func logout() async throws
    func deleteAccount() async throws
    func fetchCurrentUser() async throws -> User?
    func hasActiveSession() -> Bool
    func hasValidSession() async -> Bool
}
