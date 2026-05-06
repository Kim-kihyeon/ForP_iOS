import Foundation

public enum CourseMode: String, Codable, Equatable {
    case ordered
    case list
}

public enum CourseStatus: String, Codable, Equatable {
    case planned
    case inProgress = "in_progress"
    case completed
    case cancelled
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
    public var kakaoPlaceURL: String?
    public var memo: String?

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
        kakaoPlaceId: String? = nil,
        kakaoPlaceURL: String? = nil,
        memo: String? = nil
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
        self.kakaoPlaceURL = kakaoPlaceURL
        self.memo = memo
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
    public var status: CourseStatus
    public var visitedOrders: [Int]

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
        isEnded: Bool = false,
        status: CourseStatus? = nil,
        visitedOrders: [Int] = []
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
        self.status = status ?? (isEnded ? .completed : .planned)
        self.visitedOrders = visitedOrders
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
    public var lockedPlaces: [CoursePlace]
    public var excludedPlaces: [CoursePlace]
    public var isRandom: Bool

    public var learnedPreferences: LearnedPreferences?

    public init(
        location: String,
        themes: [String],
        placeCount: Int,
        mode: CourseMode,
        memo: String = "",
        date: Date = Date(),
        wishlistPlaces: [WishlistPlace] = [],
        baseLatitude: Double? = nil,
        baseLongitude: Double? = nil,
        searchRadius: Int = 2000,
        lockedPlaces: [CoursePlace] = [],
        excludedPlaces: [CoursePlace] = [],
        isRandom: Bool = false,
        learnedPreferences: LearnedPreferences? = nil
    ) {
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
        self.lockedPlaces = lockedPlaces
        self.excludedPlaces = excludedPlaces
        self.isRandom = isRandom
        self.learnedPreferences = learnedPreferences
    }
}

// MARK: - Learned Preferences

public struct LearnedPreferences: Equatable, Sendable {
    /// 전체 코스에서 자주 등장한 카테고리 (빈도 순)
    public var frequentCategories: [String]
    /// 별점 4+, 즐겨찾기, 데이트 완료 코스에서 추출한 선호 카테고리
    public var stronglyLikedCategories: [String]
    /// 별점 2 이하 코스에서 추출한 비선호 카테고리
    public var impliedDislikedCategories: [String]
    /// 실제 데이트 완료 횟수
    public var completedDateCount: Int

    public static let empty = LearnedPreferences(
        frequentCategories: [], stronglyLikedCategories: [],
        impliedDislikedCategories: [], completedDateCount: 0
    )

    public var isEmpty: Bool {
        frequentCategories.isEmpty && stronglyLikedCategories.isEmpty && impliedDislikedCategories.isEmpty
    }

    public init(
        frequentCategories: [String],
        stronglyLikedCategories: [String],
        impliedDislikedCategories: [String],
        completedDateCount: Int
    ) {
        self.frequentCategories = frequentCategories
        self.stronglyLikedCategories = stronglyLikedCategories
        self.impliedDislikedCategories = impliedDislikedCategories
        self.completedDateCount = completedDateCount
    }
}

extension Array where Element == Course {
    public func learnedPreferences() -> LearnedPreferences {
        guard !isEmpty else { return .empty }

        var freqMap: [String: Int] = [:]
        var likedMap: [String: Int] = [:]
        var dislikedMap: [String: Int] = [:]
        var completedCount = 0

        for course in self {
            let cats = course.places.compactMap { _shortCategory($0.category) }
            for cat in cats { freqMap[cat, default: 0] += 1 }

            let rating = course.rating ?? course.partnerRating
            let isPositive = course.isLiked || course.isEnded || (rating ?? 0) >= 4
            let isNegative = rating != nil && rating! <= 2
            if course.isEnded { completedCount += 1 }

            for cat in cats {
                if isPositive { likedMap[cat, default: 0] += 1 }
                if isNegative { dislikedMap[cat, default: 0] += 1 }
            }
        }

        let frequent: [String] = freqMap.sorted { $0.value > $1.value }.prefix(5).map(\.key)
        let liked: [String] = likedMap.sorted { $0.value > $1.value }.prefix(3).map(\.key)
        let disliked: [String] = dislikedMap.sorted { $0.value > $1.value }.prefix(3).map(\.key)
            .filter { !liked.contains($0) }

        return LearnedPreferences(
            frequentCategories: frequent,
            stronglyLikedCategories: liked,
            impliedDislikedCategories: disliked,
            completedDateCount: completedCount
        )
    }
}

private func _shortCategory(_ category: String) -> String? {
    let name = category
        .split(separator: ">")
        .last
        .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
        ?? category.trimmingCharacters(in: .whitespacesAndNewlines)
    return name.isEmpty ? nil : name
}
