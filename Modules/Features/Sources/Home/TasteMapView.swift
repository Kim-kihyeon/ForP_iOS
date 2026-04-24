import SwiftUI
import Domain
import CoreSharedUI

struct TasteMapView: View {
    let courses: [Course]
    let user: User
    let onDismiss: () -> Void

    private let allCategories: [(emoji: String, name: String)] = [
        ("☕", "카페"), ("🍳", "브런치"), ("🍽️", "음식점"), ("🍸", "술/바"),
        ("🎬", "영화"), ("🌿", "공원"), ("🖼️", "전시"), ("🎭", "문화"),
        ("🛍️", "쇼핑"), ("🎯", "액티비티"), ("🚗", "드라이브"), ("🎤", "노래방"),
        ("🏸", "스포츠"), ("🌃", "야경"), ("🧘", "힐링"),
    ]

    private var visitCounts: [String: Int] {
        var counts: [String: Int] = [:]
        for course in courses {
            for place in course.places {
                counts[place.category, default: 0] += 1
            }
        }
        return counts
    }

    private var sortedCategories: [(emoji: String, name: String, count: Int)] {
        allCategories.map { cat in
            (emoji: cat.emoji, name: cat.name, count: visitCounts[cat.name] ?? 0)
        }
        .sorted { $0.count > $1.count }
    }

    private var topCategory: String? {
        sortedCategories.first(where: { $0.count > 0 })?.name
    }

    private var insightText: String {
        let visited = sortedCategories.filter { $0.count > 0 }
        guard !visited.isEmpty else { return "아직 데이트 기록이 없어요" }
        let top = visited.prefix(2).map { $0.name }.joined(separator: "과 ")
        return "\(top)를 가장 자주 찾았어요"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        headerCard
                        tagCloudSection
                        if !courses.isEmpty { legendSection }
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("취향 지도")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") { onDismiss() }
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Brand.pink)
                }
            }
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [Brand.pink.opacity(0.85), Color(red: 1.0, green: 0.5, blue: 0.3).opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 6) {
                Text(insightText)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text("\(courses.count)개 코스 · \(courses.reduce(0) { $0 + $1.places.count })곳 방문 기반")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.top, 2)
            }
            .padding(.vertical, 28)
            .padding(.horizontal, 20)
        }
        .shadow(color: Brand.pink.opacity(0.3), radius: 16, x: 0, y: 6)
    }

    // MARK: - Tag Cloud

    private var tagCloudSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("방문 기록 기반 취향")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            FlowLayout(spacing: 10) {
                ForEach(sortedCategories, id: \.name) { item in
                    categoryTag(item)
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }

    private func categoryTag(_ item: (emoji: String, name: String, count: Int)) -> some View {
        let isPreferred = user.preferredCategories.contains(item.name)
        let isDisliked = user.dislikedCategories.contains(item.name)
        let hasVisited = item.count > 0

        let scale: TagScale = {
            if item.count >= 5 { return .large }
            if item.count >= 2 { return .medium }
            if item.count == 1 { return .small }
            return .tiny
        }()

        let bgColor: Color = {
            if isDisliked { return Color(.tertiarySystemFill) }
            if item.count >= 5 { return Brand.pink }
            if item.count >= 2 { return Brand.pink.opacity(0.7) }
            if item.count == 1 { return Brand.pink.opacity(0.35) }
            return Color(.tertiarySystemFill)
        }()

        let fgColor: Color = {
            if isDisliked { return Color(.tertiaryLabel) }
            if item.count >= 2 { return .white }
            if item.count == 1 { return Brand.pink }
            return Color(.secondaryLabel)
        }()

        return HStack(spacing: scale.iconSpacing) {
            Text(item.emoji)
                .font(.system(size: scale.emojiSize))
            Text(item.name)
                .font(.system(size: scale.fontSize, weight: scale.fontWeight))
                .foregroundStyle(fgColor)
            if hasVisited {
                Text("\(item.count)")
                    .font(.system(size: scale.badgeSize, weight: .bold))
                    .foregroundStyle(fgColor.opacity(0.8))
            }
            if isPreferred && !isDisliked {
                Image(systemName: "heart.fill")
                    .font(.system(size: scale.badgeSize - 1))
                    .foregroundStyle(item.count >= 2 ? .white.opacity(0.9) : Brand.pink)
            }
        }
        .padding(.horizontal, scale.hPad)
        .padding(.vertical, scale.vPad)
        .background(bgColor)
        .clipShape(Capsule())
        .overlay {
            if isPreferred && item.count == 0 {
                Capsule().stroke(Brand.pink.opacity(0.4), lineWidth: 1.5)
            }
        }
    }

    // MARK: - Legend

    private var legendSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("범례")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                legendRow(color: Brand.pink, label: "자주 방문 (5회 이상)")
                Divider().padding(.leading, 44)
                legendRow(color: Brand.pink.opacity(0.5), label: "가끔 방문 (1~4회)")
                Divider().padding(.leading, 44)
                legendRow(icon: "heart.fill", iconColor: Brand.pink, label: "선호한다고 설정한 카테고리")
            }
            .padding(16)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }

    private func legendRow(color: Color, label: String) -> some View {
        HStack(spacing: 12) {
            Capsule()
                .fill(color)
                .frame(width: 28, height: 14)
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.vertical, 10)
    }

    private func legendRow(icon: String, iconColor: Color, label: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(iconColor)
                .frame(width: 28)
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Tag Scale

private enum TagScale {
    case large, medium, small, tiny

    var fontSize: CGFloat {
        switch self { case .large: 15; case .medium: 13; case .small: 12; case .tiny: 11 }
    }
    var fontWeight: Font.Weight {
        switch self { case .large: .bold; case .medium: .semibold; case .small, .tiny: .medium }
    }
    var emojiSize: CGFloat {
        switch self { case .large: 16; case .medium: 14; case .small: 13; case .tiny: 11 }
    }
    var badgeSize: CGFloat {
        switch self { case .large: 12; case .medium: 11; case .small, .tiny: 10 }
    }
    var hPad: CGFloat {
        switch self { case .large: 14; case .medium: 11; case .small: 10; case .tiny: 8 }
    }
    var vPad: CGFloat {
        switch self { case .large: 10; case .medium: 8; case .small: 7; case .tiny: 6 }
    }
    var iconSpacing: CGFloat {
        switch self { case .large: 5; case .medium: 4; case .small, .tiny: 3 }
    }
}

