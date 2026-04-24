import Foundation
import SwiftData
import Domain

@Model
final class CourseCache {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var title: String
    var date: Date
    var modeRaw: String
    var placesData: Data
    var promptSummary: String
    var outfitSuggestion: String?
    var courseReason: String = ""
    var isLiked: Bool = false
    var rating: Int?
    var review: String?
    var isEnded: Bool = false

    init(from course: Course) throws {
        self.id = course.id
        self.userId = course.userId
        self.title = course.title
        self.date = course.date
        self.modeRaw = course.mode.rawValue
        self.placesData = try JSONEncoder().encode(course.places)
        self.promptSummary = course.promptSummary
        self.outfitSuggestion = course.outfitSuggestion
        self.courseReason = course.courseReason
        self.isLiked = course.isLiked
        self.rating = course.rating
        self.review = course.review
        self.isEnded = course.isEnded
    }

    func toDomain() throws -> Course {
        let places = try JSONDecoder().decode([CoursePlace].self, from: placesData)
        return Course(
            id: id,
            userId: userId,
            title: title,
            date: date,
            mode: CourseMode(rawValue: modeRaw) ?? .ordered,
            places: places,
            promptSummary: promptSummary,
            outfitSuggestion: outfitSuggestion,
            courseReason: courseReason,
            isLiked: isLiked,
            rating: rating,
            review: review,
            isEnded: isEnded
        )
    }
}
