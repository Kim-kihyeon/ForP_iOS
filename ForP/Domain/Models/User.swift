import Foundation

struct User: Identifiable, Codable {
    var id: UUID
    var email: String
    var nickname: String
    var preferredCategories: [String]
    var dislikedCategories: [String]
    var preferredThemes: [String]
    var location: String
}
