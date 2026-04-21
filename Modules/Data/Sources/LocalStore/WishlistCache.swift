import Foundation
import SwiftData
import Domain

@Model
final class WishlistCache {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var keyword: String
    var placeName: String?
    var address: String?
    var latitude: Double?
    var longitude: Double?
    var category: String
    var savedAt: Date

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
