import Foundation
import Supabase
import Domain

public final class UserRepository: UserRepositoryProtocol {
    private let supabase: SupabaseClient

    public init(supabase: SupabaseClient) {
        self.supabase = supabase
    }

    public func fetchCurrentUser() async throws -> Domain.User {
        let row: UserRow = try await supabase
            .from("users")
            .select()
            .eq("id", value: try await supabase.auth.user().id)
            .single()
            .execute()
            .value
        return row.toDomain()
    }

    public func updateUser(_ user: Domain.User) async throws {
        let row = UserRow(from: user)
        try await supabase
            .from("users")
            .upsert(row)
            .execute()
    }

    public func saveFCMToken(userId: UUID, token: String) async throws {
        try await supabase
            .from("users")
            .update(["fcm_token": token])
            .eq("id", value: userId)
            .execute()
    }
}

