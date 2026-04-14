import Foundation

public struct Partner: Identifiable, Codable, Equatable {
    public var id: UUID
    public var userId: UUID
    public var nickname: String
    public var preferredCategories: [String]
    public var dislikedCategories: [String]
    public var preferredThemes: [String]
    public var notes: String

    public init(
        id: UUID = UUID(),
        userId: UUID,
        nickname: String,
        preferredCategories: [String] = [],
        dislikedCategories: [String] = [],
        preferredThemes: [String] = [],
        notes: String = ""
    ) {
        self.id = id
        self.userId = userId
        self.nickname = nickname
        self.preferredCategories = preferredCategories
        self.dislikedCategories = dislikedCategories
        self.preferredThemes = preferredThemes
        self.notes = notes
    }
}
