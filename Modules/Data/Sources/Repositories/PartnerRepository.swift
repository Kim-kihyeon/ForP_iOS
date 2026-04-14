import Foundation
import Supabase
import Domain

public final class PartnerRepository: PartnerRepositoryProtocol {
    private let supabase: SupabaseClient

    public init(supabase: SupabaseClient) {
        self.supabase = supabase
    }

    public func fetchPartner(for userId: UUID) async throws -> Partner? {
        let rows: [PartnerRow] = try await supabase
            .from("partners")
            .select()
            .eq("user_id", value: userId)
            .limit(1)
            .execute()
            .value
        return rows.first?.toDomain()
    }

    public func savePartner(_ partner: Partner) async throws {
        let row = PartnerRow(from: partner)
        try await supabase
            .from("partners")
            .upsert(row)
            .execute()
    }

    public func deletePartner(id: UUID) async throws {
        try await supabase
            .from("partners")
            .delete()
            .eq("id", value: id)
            .execute()
    }
}

private struct PartnerRow: Codable {
    let id: UUID
    let userId: UUID
    let nickname: String
    let preferredCategories: [String]
    let dislikedCategories: [String]
    let preferredThemes: [String]
    let notes: String

    enum CodingKeys: String, CodingKey {
        case id, nickname, notes
        case userId = "user_id"
        case preferredCategories = "preferred_categories"
        case dislikedCategories = "disliked_categories"
        case preferredThemes = "preferred_themes"
    }

    init(from partner: Partner) {
        id = partner.id
        userId = partner.userId
        nickname = partner.nickname
        preferredCategories = partner.preferredCategories
        dislikedCategories = partner.dislikedCategories
        preferredThemes = partner.preferredThemes
        notes = partner.notes
    }

    func toDomain() -> Partner {
        Partner(
            id: id,
            userId: userId,
            nickname: nickname,
            preferredCategories: preferredCategories,
            dislikedCategories: dislikedCategories,
            preferredThemes: preferredThemes,
            notes: notes
        )
    }
}
