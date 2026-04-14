import Foundation
import Supabase
import Domain

public final class PartnerRepository: PartnerRepositoryProtocol {
    private let supabase: SupabaseClient

    public init(supabase: SupabaseClient) {
        self.supabase = supabase
    }

    public func fetchPartner(for userId: UUID) async throws -> Partner? {
        // TODO: Supabase DB에서 파트너 조회
        return nil
    }

    public func savePartner(_ partner: Partner) async throws {
        // TODO: Supabase DB upsert
    }

    public func deletePartner(id: UUID) async throws {
        // TODO: Supabase DB 삭제
    }
}
