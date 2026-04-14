import Foundation
import Supabase
import Domain

public final class AnniversaryRepository: AnniversaryRepositoryProtocol, @unchecked Sendable {
    private let supabase: SupabaseClient

    public init(supabase: SupabaseClient) {
        self.supabase = supabase
    }

    public func fetchAnniversaries(userId: UUID) async throws -> [Anniversary] {
        let rows: [AnniversaryRow] = try await supabase
            .from("anniversaries")
            .select()
            .eq("user_id", value: userId)
            .order("date")
            .execute()
            .value
        return rows.map { $0.toDomain() }
    }

    public func saveAnniversary(_ anniversary: Anniversary) async throws {
        let row = AnniversaryInsertRow(from: anniversary)
        try await supabase
            .from("anniversaries")
            .upsert(row)
            .execute()
    }

    public func deleteAnniversary(id: UUID) async throws {
        try await supabase
            .from("anniversaries")
            .delete()
            .eq("id", value: id)
            .execute()
    }
}

private struct AnniversaryInsertRow: Encodable {
    let id: UUID
    let userId: UUID
    let name: String
    let date: String

    enum CodingKeys: String, CodingKey {
        case id, name, date
        case userId = "user_id"
    }

    init(from a: Anniversary) {
        id = a.id
        userId = a.userId
        name = a.name
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        date = formatter.string(from: a.date)
    }
}

private struct AnniversaryRow: Decodable {
    let id: UUID
    let userId: UUID
    let name: String
    let date: String

    enum CodingKeys: String, CodingKey {
        case id, name, date
        case userId = "user_id"
    }

    func toDomain() -> Anniversary {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return Anniversary(
            id: id,
            userId: userId,
            name: name,
            date: formatter.date(from: date) ?? Date()
        )
    }
}
