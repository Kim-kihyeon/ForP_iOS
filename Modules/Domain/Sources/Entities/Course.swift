import Foundation

public enum CourseMode: String, Codable, Equatable {
    case ordered
    case list
}

public struct CoursePlace: Codable, Equatable {
    public var order: Int
    public var category: String
    public var keyword: String
    public var reason: String
    public var menu: String?
    public var placeName: String?
    public var address: String?
    public var latitude: Double?
    public var longitude: Double?
    public var kakaoPlaceId: String?

    public init(
        order: Int,
        category: String,
        keyword: String,
        reason: String,
        menu: String? = nil,
        placeName: String? = nil,
        address: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        kakaoPlaceId: String? = nil
    ) {
        self.order = order
        self.category = category
        self.keyword = keyword
        self.reason = reason
        self.menu = menu
        self.placeName = placeName
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.kakaoPlaceId = kakaoPlaceId
    }
}

public struct Course: Identifiable, Codable, Equatable {
    public var id: UUID
    public var userId: UUID
    public var title: String
    public var date: Date
    public var mode: CourseMode
    public var places: [CoursePlace]
    public var candidates: [CoursePlace]
    public var outfitSuggestion: String?
    public var courseReason: String
    public var partnerId: UUID?
    public var isLiked: Bool
    public var rating: Int?
    public var review: String?
    public var partnerRating: Int?
    public var partnerReview: String?
    public var isEnded: Bool

    public init(
        id: UUID = UUID(),
        userId: UUID,
        partnerId: UUID? = nil,
        title: String,
        date: Date = Date(),
        mode: CourseMode,
        places: [CoursePlace],
        candidates: [CoursePlace] = [],
        outfitSuggestion: String? = nil,
        courseReason: String = "",
        isLiked: Bool = false,
        rating: Int? = nil,
        review: String? = nil,
        partnerRating: Int? = nil,
        partnerReview: String? = nil,
        isEnded: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.partnerId = partnerId
        self.title = title
        self.date = date
        self.mode = mode
        self.places = places
        self.candidates = candidates
        self.outfitSuggestion = outfitSuggestion
        self.courseReason = courseReason
        self.isLiked = isLiked
        self.rating = rating
        self.review = review
        self.partnerRating = partnerRating
        self.partnerReview = partnerReview
        self.isEnded = isEnded
    }
}

extension Course {
    public var averageRating: Double? {
        switch (rating, partnerRating) {
        case let (r?, p?): return Double(r + p) / 2.0
        case let (r?, nil): return Double(r)
        case let (nil, p?): return Double(p)
        case (nil, nil): return nil
        }
    }
}

public struct CoursePlan: Equatable {
    public var places: [CoursePlace]
    public var candidates: [CoursePlace]
    public var outfitSuggestion: String
    public var courseReason: String

    public init(places: [CoursePlace], candidates: [CoursePlace] = [], outfitSuggestion: String, courseReason: String = "") {
        self.places = places
        self.candidates = candidates
        self.outfitSuggestion = outfitSuggestion
        self.courseReason = courseReason
    }
}

public struct CourseOptions: Equatable {
    public var location: String
    public var themes: [String]
    public var placeCount: Int
    public var mode: CourseMode
    public var memo: String
    public var date: Date
    public var weatherDescription: String?
    public var wishlistPlaces: [WishlistPlace]
    public var baseLatitude: Double?
    public var baseLongitude: Double?
    public var searchRadius: Int

    public init(location: String, themes: [String], placeCount: Int, mode: CourseMode, memo: String = "", date: Date = Date(), wishlistPlaces: [WishlistPlace] = [], baseLatitude: Double? = nil, baseLongitude: Double? = nil, searchRadius: Int = 2000) {
        self.location = location
        self.themes = themes
        self.placeCount = placeCount
        self.mode = mode
        self.memo = memo
        self.date = date
        self.wishlistPlaces = wishlistPlaces
        self.baseLatitude = baseLatitude
        self.baseLongitude = baseLongitude
        self.searchRadius = searchRadius
    }
}
