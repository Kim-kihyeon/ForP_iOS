import Foundation
import SwiftData
import Domain

@Model
final class CourseCache {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var partnerId: UUID?
    var title: String
    var date: Date
    var modeRaw: String
    var placesData: Data
    var candidatesData: Data
    var outfitSuggestion: String?
    var courseReason: String = ""
    var isLiked: Bool = false
    var rating: Int?
    var review: String?
    var partnerRating: Int?
    var partnerReview: String?
    var isEnded: Bool = false

    init(from course: Course) throws {
        self.id = course.id
        self.userId = course.userId
        self.partnerId = course.partnerId
        self.title = course.title
        self.date = course.date
        self.modeRaw = course.mode.rawValue
        self.placesData = try JSONEncoder().encode(course.places)
        self.candidatesData = try JSONEncoder().encode(course.candidates)
        self.outfitSuggestion = course.outfitSuggestion
        self.courseReason = course.courseReason
        self.isLiked = course.isLiked
        self.rating = course.rating
        self.review = course.review
        self.partnerRating = course.partnerRating
        self.partnerReview = course.partnerReview
        self.isEnded = course.isEnded
    }

    func toDomain() throws -> Course {
        let places = try JSONDecoder().decode([CoursePlace].self, from: placesData)
        let candidates = (try? JSONDecoder().decode([CoursePlace].self, from: candidatesData)) ?? []
        return Course(
            id: id,
            userId: userId,
            partnerId: partnerId,
            title: title,
            date: date,
            mode: CourseMode(rawValue: modeRaw) ?? .ordered,
            places: places,
            candidates: candidates,
            outfitSuggestion: outfitSuggestion,
            courseReason: courseReason,
            isLiked: isLiked,
            rating: rating,
            review: review,
            partnerRating: partnerRating,
            partnerReview: partnerReview,
            isEnded: isEnded
        )
    }
}
