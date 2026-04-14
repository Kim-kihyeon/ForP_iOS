import Foundation
import Supabase
import Domain

public final class UserRepository: UserRepositoryProtocol {
    private let supabase: SupabaseClient

    public init(supabase: SupabaseClient) {
        self.supabase = supabase
    }

    public func fetchCurrentUser() async throws -> Domain.User {
        // TODO: Supabase Auth + DB에서 유저 정보 조회
        throw URLError(.notConnectedToInternet)
    }

    public func updateUser(_ user: Domain.User) async throws {
        // TODO: Supabase DB 업데이트
    }
}
