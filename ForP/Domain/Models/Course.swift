import Foundation

enum CourseMode: String, Codable {
    case ordered
    case list
}

struct CoursePlace: Codable {
    var order: Int
    var category: String
    var keyword: String
    var reason: String
    var placeName: String?
    var address: String?
    var latitude: Double?
    var longitude: Double?
}

struct Course: Identifiable, Codable {
    var id: UUID
    var userId: UUID
    var title: String
    var date: Date
    var mode: CourseMode
    var places: [CoursePlace]
    var promptSummary: String
}
