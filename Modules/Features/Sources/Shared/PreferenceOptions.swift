import Foundation

struct PreferenceOption: Equatable, Identifiable {
    let emoji: String
    let name: String
    let systemImage: String?

    var id: String { name }

    init(_ emoji: String, _ name: String, systemImage: String? = nil) {
        self.emoji = emoji
        self.name = name
        self.systemImage = systemImage
    }
}

enum PreferenceOptions {
    static let categories: [PreferenceOption] = [
        .init("☕", "카페"),
        .init("🍳", "브런치"),
        .init("🍽️", "음식점"),
        .init("🍸", "술/바"),
        .init("🎬", "영화"),
        .init("🌿", "공원"),
        .init("🖼️", "전시"),
        .init("🎭", "문화"),
        .init("🛍️", "쇼핑"),
        .init("🎯", "액티비티"),
        .init("🚗", "드라이브"),
        .init("🎤", "노래방"),
        .init("🏸", "스포츠"),
        .init("🌃", "야경"),
        .init("🧘", "힐링"),
    ]

    static let themes: [PreferenceOption] = [
        .init("🤫", "조용한", systemImage: "speaker.slash.fill"),
        .init("⚡", "활동적인", systemImage: "bolt.fill"),
        .init("🌸", "감성적인", systemImage: "sparkles"),
        .init("🍜", "맛집 탐방", systemImage: "fork.knife"),
        .init("🌿", "자연", systemImage: "leaf.fill"),
        .init("🏙️", "도심", systemImage: "building.2.fill"),
        .init("✨", "이색적인", systemImage: "wand.and.stars"),
        .init("💬", "대화하기 좋은", systemImage: "bubble.left.and.bubble.right.fill"),
        .init("📸", "사진 찍기 좋은", systemImage: "camera.fill"),
        .init("💸", "가성비", systemImage: "wonsign.circle.fill"),
        .init("💎", "럭셔리", systemImage: "diamond.fill"),
        .init("🏠", "실내 위주", systemImage: "house.fill"),
        .init("🌤️", "야외 위주", systemImage: "sun.max.fill"),
        .init("🌃", "야경", systemImage: "moon.stars.fill"),
        .init("🍰", "디저트", systemImage: "birthday.cake.fill"),
        .init("🍷", "술 한잔", systemImage: "wineglass.fill"),
        .init("🚶", "산책", systemImage: "figure.walk"),
        .init("🚗", "드라이브", systemImage: "car.fill"),
    ]

    static let blacklistPresets: [PreferenceOption] = [
        .init("🥜", "견과류"),
        .init("🦐", "해산물"),
        .init("🥛", "유제품"),
        .init("🌾", "글루텐"),
        .init("🌶️", "매운 음식"),
        .init("🍺", "알코올"),
        .init("🥩", "육류"),
        .init("🐷", "돼지고기"),
        .init("🐟", "날음식/회"),
        .init("☕", "카페인"),
    ]
}
