import Foundation

public struct WishlistPlace: Identifiable, Equatable, Codable {
    public var id: UUID
    public var userId: UUID
    public var keyword: String
    public var placeName: String?
    public var address: String?
    public var latitude: Double?
    public var longitude: Double?
    public var category: String
    public var savedAt: Date

    public init(
        id: UUID = UUID(),
        userId: UUID,
        keyword: String,
        placeName: String? = nil,
        address: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        category: String,
        savedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.keyword = keyword
        self.placeName = placeName
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.category = category
        self.savedAt = savedAt
    }

}
