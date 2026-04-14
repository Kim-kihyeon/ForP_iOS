import Foundation
import KakaoSDKUser
import KakaoSDKAuth
import Supabase
import Domain

public final class AuthRepository: AuthRepositoryProtocol {
    private let supabase: SupabaseClient

    public init(supabase: SupabaseClient) {
        self.supabase = supabase
    }

    public func loginWithKakao() async throws -> Domain.User {
        _ = try await kakaoLogin()
        let kakaoUser = try await fetchKakaoUser()

        return Domain.User(
            id: UUID(),
            email: kakaoUser?.kakaoAccount?.email ?? "",
            nickname: kakaoUser?.kakaoAccount?.profile?.nickname ?? "사용자",
            preferredCategories: [],
            dislikedCategories: [],
            preferredThemes: [],
            location: ""
        )
    }

    public func loginWithApple(idToken: String, nonce: String) async throws -> Domain.User {
        let session = try await supabase.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
        )

        let authUser = session.user
        return Domain.User(
            id: UUID(uuidString: authUser.id.uuidString) ?? UUID(),
            email: authUser.email ?? "",
            nickname: authUser.userMetadata["full_name"]?.stringValue ?? "사용자",
            preferredCategories: [],
            dislikedCategories: [],
            preferredThemes: [],
            location: ""
        )
    }

    public func logout() async throws {
        try await supabase.auth.signOut()
    }

    public func fetchCurrentUser() async throws -> Domain.User? {
        guard let authUser = try? await supabase.auth.user() else { return nil }
        return Domain.User(
            id: UUID(uuidString: authUser.id.uuidString) ?? UUID(),
            email: authUser.email ?? "",
            nickname: authUser.userMetadata["full_name"]?.stringValue ?? "사용자",
            preferredCategories: [],
            dislikedCategories: [],
            preferredThemes: [],
            location: ""
        )
    }

    // MARK: - Private

    private func kakaoLogin() async throws -> OAuthToken {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                if UserApi.isKakaoTalkLoginAvailable() {
                    UserApi.shared.loginWithKakaoTalk { token, error in
                        if let error { continuation.resume(throwing: error) }
                        else if let token { continuation.resume(returning: token) }
                    }
                } else {
                    UserApi.shared.loginWithKakaoAccount { token, error in
                        if let error { continuation.resume(throwing: error) }
                        else if let token { continuation.resume(returning: token) }
                    }
                }
            }
        }
    }

    private func fetchKakaoUser() async throws -> KakaoSDKUser.User? {
        try await withCheckedThrowingContinuation { continuation in
            UserApi.shared.me { user, error in
                if let error { continuation.resume(throwing: error) }
                else { continuation.resume(returning: user) }
            }
        }
    }
}
