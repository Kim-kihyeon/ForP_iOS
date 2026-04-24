import Foundation
import Supabase
import Domain

public final class PartnerConnectionRepository: PartnerConnectionRepositoryProtocol {
    private let supabase: SupabaseClient

    public init(supabase: SupabaseClient) {
        self.supabase = supabase
    }

    public func getOrCreateMyCode(userId: UUID) async throws -> String {
        struct CodeRow: Decodable {
            let inviteCode: String?
            enum CodingKeys: String, CodingKey { case inviteCode = "invite_code" }
        }
        let rows: [CodeRow] = try await supabase
            .from("users")
            .select("invite_code")
            .eq("id", value: userId)
            .execute()
            .value

        if let code = rows.first?.inviteCode {
            return code
        }

        let code = String((0..<6).map { _ in "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".randomElement()! })
        try await supabase
            .from("users")
            .update(["invite_code": code])
            .eq("id", value: userId)
            .execute()
        return code
    }

    public func connect(code: String, myUserId: UUID) async throws -> PartnerConnection {
        struct RPCResult: Decodable { let findUserByInviteCode: UUID? }
        let partnerId: UUID? = try await supabase
            .rpc("find_user_by_invite_code", params: ["code": code])
            .execute()
            .value

        guard let partnerId else {
            throw PartnerConnectionError.codeNotFound
        }
        guard partnerId != myUserId else {
            throw PartnerConnectionError.cannotConnectToSelf
        }

        struct InsertRow: Encodable {
            let requesterId: UUID
            let receiverId: UUID
            let status: String
            let inviteCode: String
            enum CodingKeys: String, CodingKey {
                case requesterId = "requester_id"
                case receiverId = "receiver_id"
                case status
                case inviteCode = "invite_code"
            }
        }
        let row = InsertRow(requesterId: myUserId, receiverId: partnerId, status: "accepted", inviteCode: code)
        let connections: [PartnerConnection] = try await supabase
            .from("partner_connections")
            .insert(row)
            .select()
            .execute()
            .value

        guard let connection = connections.first else {
            throw PartnerConnectionError.connectionFailed
        }
        return connection
    }

    public func fetchConnection(userId: UUID) async throws -> PartnerConnection? {
        let connections: [PartnerConnection] = try await supabase
            .from("partner_connections")
            .select()
            .or("requester_id.eq.\(userId),receiver_id.eq.\(userId)")
            .eq("status", value: "accepted")
            .execute()
            .value
        return connections.first
    }

    public func fetchUser(id: UUID) async throws -> Domain.User {
        struct UserRow: Decodable {
            let id: UUID
            let email: String
            let nickname: String
            let preferredCategories: [String]
            let dislikedCategories: [String]
            let preferredThemes: [String]
            let location: String
            let foodBlacklist: [String]
            enum CodingKeys: String, CodingKey {
                case id, email, nickname, location
                case preferredCategories = "preferred_categories"
                case dislikedCategories = "disliked_categories"
                case preferredThemes = "preferred_themes"
                case foodBlacklist = "food_blacklist"
            }
        }
        let rows: [UserRow] = try await supabase
            .from("users")
            .select()
            .eq("id", value: id)
            .execute()
            .value
        guard let row = rows.first else { throw PartnerConnectionError.userNotFound }
        return Domain.User(
            id: row.id,
            email: row.email,
            nickname: row.nickname,
            preferredCategories: row.preferredCategories,
            dislikedCategories: row.dislikedCategories,
            preferredThemes: row.preferredThemes,
            location: row.location,
            foodBlacklist: row.foodBlacklist
        )
    }

    public func disconnect(connectionId: UUID) async throws {
        try await supabase
            .from("partner_connections")
            .delete()
            .eq("id", value: connectionId)
            .execute()
    }
}
