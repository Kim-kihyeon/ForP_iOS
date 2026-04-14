import Foundation
import Domain

struct UserRow: Codable {
    let id: UUID
    let email: String
    let nickname: String
    let preferredCategories: [String]
    let dislikedCategories: [String]
    let preferredThemes: [String]
    let location: String

    enum CodingKeys: String, CodingKey {
        case id, email, nickname, location
        case preferredCategories = "preferred_categories"
        case dislikedCategories = "disliked_categories"
        case preferredThemes = "preferred_themes"
    }

    init(from user: Domain.User) {
        id = user.id
        email = user.email
        nickname = user.nickname
        preferredCategories = user.preferredCategories
        dislikedCategories = user.dislikedCategories
        preferredThemes = user.preferredThemes
        location = user.location
    }

    func toDomain() -> Domain.User {
        Domain.User(
            id: id,
            email: email,
            nickname: nickname,
            preferredCategories: preferredCategories,
            dislikedCategories: dislikedCategories,
            preferredThemes: preferredThemes,
            location: location
        )
    }
}
