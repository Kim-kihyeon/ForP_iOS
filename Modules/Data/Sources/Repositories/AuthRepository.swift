import Foundation
import KakaoSDKUser
import KakaoSDKAuth
import Supabase
import Domain

public final class AuthRepository: AuthRepositoryProtocol {
    private let supabase: SupabaseClient
    private let anonKey: String

    public init(supabase: SupabaseClient, anonKey: String) {
        self.supabase = supabase
        self.anonKey = anonKey
    }

    public func loginWithKakao() async throws -> Domain.User {
        let kakaoToken = try await kakaoLogin()
        let kakaoUser = try await fetchKakaoUser()
        let nickname = kakaoUser?.kakaoAccount?.profile?.nickname ?? "사용자"
        let email = kakaoUser?.kakaoAccount?.email ?? ""

        // Edge Function으로 카카오 토큰 → Supabase 세션 교환
        do {
            let response: KakaoAuthResponse = try await supabase.functions
                .invoke("kakao-auth", options: .init(
                    headers: ["Authorization": "Bearer \(anonKey)"],
                    body: ["accessToken": kakaoToken.accessToken]
                ))
            let session = try await supabase.auth.setSession(
                accessToken: response.accessToken,
                refreshToken: response.refreshToken
            )
            let userId = session.user.id
            let user = Domain.User(
                id: userId,
                email: email.isEmpty ? response.email : email,
                nickname: nickname
            )
            return try await fetchUserRow(id: userId, fallback: user)
        } catch {
            throw error
        }

    }

    public func loginWithApple(idToken: String, nonce: String) async throws -> Domain.User {
        let session = try await supabase.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
        )

        let authUser = session.user
        let user = Domain.User(
            id: UUID(uuidString: authUser.id.uuidString) ?? UUID(),
            email: authUser.email ?? "",
            nickname: authUser.userMetadata["full_name"]?.stringValue ?? "사용자",
            preferredCategories: [],
            dislikedCategories: [],
            preferredThemes: [],
            location: ""
        )
        return try await fetchUserRow(id: authUser.id, fallback: user)
    }

    public func logout() async throws {
        try await supabase.auth.signOut()
    }

    public func deleteAccount() async throws {
        let accessToken = try await supabase.auth.session.accessToken
        try await supabase.functions.invoke(
            "delete-account",
            options: .init(headers: ["Authorization": "Bearer \(accessToken)"])
        )
        try? await supabase.auth.signOut()
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

    public func hasActiveSession() -> Bool {
        supabase.auth.currentSession != nil
    }

    public func hasValidSession() async -> Bool {
        return supabase.auth.currentSession != nil
    }

    // MARK: - Private

    private struct KakaoAuthResponse: Decodable {
        let accessToken: String
        let refreshToken: String
        let userId: String
        let email: String
        let nickname: String

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case refreshToken = "refresh_token"
            case userId = "user_id"
            case email, nickname
        }
    }

    private func kakaoLogin() async throws -> OAuthToken {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                if UserApi.isKakaoTalkLoginAvailable() {
                    UserApi.shared.loginWithKakaoTalk { token, error in
                        if let error { continuation.resume(throwing: error) }
                        else if let token { continuation.resume(returning: token) }
                        else { continuation.resume(throwing: URLError(.unknown)) }
                    }
                } else {
                    UserApi.shared.loginWithKakaoAccount { token, error in
                        if let error { continuation.resume(throwing: error) }
                        else if let token { continuation.resume(returning: token) }
                        else { continuation.resume(throwing: URLError(.unknown)) }
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

    private func fetchUserRow(id: UUID, fallback: Domain.User) async throws -> Domain.User {
        if let row: UserRow = try? await supabase
            .from("users")
            .select()
            .eq("id", value: id)
            .single()
            .execute()
            .value {
            return row.toDomain()
        }

        var user = fallback
        user.id = id
        return user
    }
}
