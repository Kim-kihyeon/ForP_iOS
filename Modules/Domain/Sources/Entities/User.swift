import Foundation

public struct User: Identifiable, Codable, Equatable {
    public var id: UUID
    public var email: String
    public var nickname: String
    public var preferredCategories: [String]
    public var dislikedCategories: [String]
    public var preferredThemes: [String]
    public var location: String
    public var foodBlacklist: [String]

    public static let placeholder = User(email: "", nickname: "")

    public init(
        id: UUID = UUID(),
        email: String,
        nickname: String,
        preferredCategories: [String] = [],
        dislikedCategories: [String] = [],
        preferredThemes: [String] = [],
        location: String = "",
        foodBlacklist: [String] = []
    ) {
        self.id = id
        self.email = email
        self.nickname = nickname
        self.preferredCategories = preferredCategories
        self.dislikedCategories = dislikedCategories
        self.preferredThemes = preferredThemes
        self.location = location
        self.foodBlacklist = foodBlacklist
    }
}
