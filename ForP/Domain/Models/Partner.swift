import Foundation

struct Partner: Identifiable, Codable {
    var id: UUID
    var userId: UUID
    var nickname: String
    var preferredCategories: [String]
    var dislikedCategories: [String]
    var preferredThemes: [String]
    var notes: String
}
