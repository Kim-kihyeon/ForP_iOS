import SwiftUI
import Domain
import CoreSharedUI

struct MonthlyReportView: View {
    let courses: [Course]
    let isLoading: Bool
    let onDismiss: () -> Void

    private var cal: Calendar { Calendar.current }
    private var now: Date { Date() }
    private var year: Int { cal.component(.year, from: now) }
    private var month: Int { cal.component(.month, from: now) }

    private var totalPlaces: Int {
        courses.reduce(0) { $0 + $1.places.count }
    }

    private var averageRating: Double? {
        let rated = courses.compactMap { $0.rating }
        guard !rated.isEmpty else { return nil }
        return Double(rated.reduce(0, +)) / Double(rated.count)
    }

    private var topCategories: [(name: String, count: Int)] {
        var counts: [String: Int] = [:]
        for course in courses {
            for place in course.places {
                counts[place.category, default: 0] += 1
            }
        }
        return counts.map { (name: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
            .prefix(3)
            .map { $0 }
    }

    private var bestCourse: Course? {
        courses.filter { $0.rating != nil }.max { ($0.rating ?? 0) < ($1.rating ?? 0) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if courses.isEmpty {
                    emptyState
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            headerCard
                            statsGrid
                            if !topCategories.isEmpty { categoriesSection }
                            if let best = bestCourse { bestCourseSection(best) }
                        }
                        .padding(.horizontal, Spacing.lg)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("\(month)월 리포트")
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
                        colors: [Brand.pink, Brand.pink.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 6) {
                Text("\(year)년 \(month)월")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))

                Text("이번 달 \(courses.count)번 데이트했어요")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)

                Text("총 \(totalPlaces)곳을 함께 다녔어요")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.top, 2)
            }
            .padding(.vertical, 28)
        }
        .shadow(color: Brand.pink.opacity(0.3), radius: 16, x: 0, y: 6)
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            statCard(
                icon: "heart.fill",
                iconColor: Brand.pink,
                label: "데이트",
                value: "\(courses.count)번"
            )
            statCard(
                icon: "mappin.circle.fill",
                iconColor: Brand.iconBlue,
                label: "방문 장소",
                value: "\(totalPlaces)곳"
            )
            statCard(
                icon: "star.fill",
                iconColor: .yellow,
                label: "평균 별점",
                value: averageRating.map { String(format: "%.1f점", $0) } ?? "-"
            )
            statCard(
                icon: "heart.text.square.fill",
                iconColor: .orange,
                label: "즐겨찾기",
                value: "\(courses.filter { $0.isLiked }.count)개"
            )
        }
    }

    private func statCard(icon: String, iconColor: Color, label: String, value: String) -> some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(iconColor)
            }
            VStack(spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .bold))
                Text(label)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Categories

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("자주 간 장소")

            let maxCount = topCategories.first?.count ?? 1
            VStack(spacing: 10) {
                ForEach(Array(topCategories.enumerated()), id: \.offset) { index, item in
                    categoryRow(rank: index + 1, name: item.name, count: item.count, maxCount: maxCount)
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }

    private func categoryRow(rank: Int, name: String, count: Int, maxCount: Int) -> some View {
        HStack(spacing: 12) {
            Text("\(rank)")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(rank == 1 ? Brand.pink : .secondary)
                .frame(width: 18)

            Text(name)
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 60, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.tertiarySystemFill))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(rank == 1 ? Brand.pink : Brand.pink.opacity(0.5))
                        .frame(width: geo.size.width * CGFloat(count) / CGFloat(maxCount), height: 8)
                }
            }
            .frame(height: 8)

            Text("\(count)회")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 30, alignment: .trailing)
        }
    }

    // MARK: - Best Course

    private func bestCourseSection(_ course: Course) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("이번 달 최고의 데이트")

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(course.title)
                            .font(.system(size: 16, weight: .bold))
                        Text(course.places.compactMap { $0.placeName ?? $0.keyword }.prefix(3).joined(separator: " · "))
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    if let rating = course.rating {
                        HStack(spacing: 3) {
                            ForEach(1...5, id: \.self) { i in
                                Image(systemName: i <= rating ? "star.fill" : "star")
                                    .font(.system(size: 12))
                                    .foregroundStyle(i <= rating ? Color.yellow : Color(.tertiaryLabel))
                            }
                        }
                    }
                }

                if let review = course.review, !review.isEmpty {
                    Text("\"\(review)\"")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .italic()
                        .lineLimit(2)
                }
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: [Brand.softPink.opacity(0.5), Color(.systemBackground)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Brand.softPink, lineWidth: 1.5))
            .shadow(color: Brand.pink.opacity(0.08), radius: 8, x: 0, y: 2)
        }
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 48))
                .foregroundStyle(Color(.tertiaryLabel))
            Text("이번 달엔 아직 데이트가 없어요")
                .font(.system(size: 17, weight: .semibold))
            Text("코스를 만들고 함께 다녀봐요")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.secondary)
            .padding(.leading, 4)
    }
}
