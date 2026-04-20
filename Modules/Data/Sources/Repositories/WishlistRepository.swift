import Foundation
import Supabase
import Domain

public struct WishlistRepository: WishlistRepositoryProtocol {
    private let supabase: SupabaseClient

    public init(supabase: SupabaseClient) {
        self.supabase = supabase
    }

    public func fetchAll(userId: UUID) async throws -> [WishlistPlace] {
        let rows: [WishlistRow] = try await supabase
            .from("wishlist_places")
            .select()
            .eq("user_id", value: userId)
            .order("saved_at", ascending: false)
            .execute()
            .value
        return rows.map { $0.toDomain() }
    }

    public func save(_ place: WishlistPlace) async throws {
        try await supabase
            .from("wishlist_places")
            .delete()
            .eq("user_id", value: place.userId)
            .eq("keyword", value: place.keyword)
            .execute()
        try await supabase
            .from("wishlist_places")
            .insert(WishlistInsertRow(from: place))
            .execute()
    }

    public func delete(id: UUID) async throws {
        try await supabase
            .from("wishlist_places")
            .delete()
            .eq("id", value: id)
            .execute()
    }
}

private struct WishlistRow: Decodable {
    let id: UUID
    let userId: UUID
    let keyword: String
    let placeName: String?
    let address: String?
    let latitude: Double?
    let longitude: Double?
    let category: String
    let savedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case keyword
        case placeName = "place_name"
        case address
        case latitude
        case longitude
        case category
        case savedAt = "saved_at"
    }

    func toDomain() -> WishlistPlace {
        WishlistPlace(
            id: id,
            userId: userId,
            keyword: keyword,
            placeName: placeName,
            address: address,
            latitude: latitude,
            longitude: longitude,
            category: category,
            savedAt: savedAt
        )
    }
}

private struct WishlistInsertRow: Encodable {
    let id: UUID
    let userId: UUID
    let keyword: String
    let placeName: String?
    let address: String?
    let latitude: Double?
    let longitude: Double?
    let category: String
    let savedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case keyword
        case placeName = "place_name"
        case address
        case latitude
        case longitude
        case category
        case savedAt = "saved_at"
    }

    init(from place: WishlistPlace) {
        self.id = place.id
        self.userId = place.userId
        self.keyword = place.keyword
        self.placeName = place.placeName
        self.address = place.address
        self.latitude = place.latitude
        self.longitude = place.longitude
        self.category = place.category
        self.savedAt = place.savedAt
    }
}
