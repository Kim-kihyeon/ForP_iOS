import SwiftUI
import ComposableArchitecture
import CoreSharedUI
import Domain

public struct HomeView: View {
    @Bindable var store: StoreOf<HomeFeature>

    private let courseGradients: [[Color]] = [
        [Color(red: 1.0, green: 0.45, blue: 0.6), Color(red: 1.0, green: 0.7, blue: 0.5)],
        [Color(red: 0.4, green: 0.6, blue: 1.0), Color(red: 0.6, green: 0.85, blue: 1.0)],
        [Color(red: 0.6, green: 0.4, blue: 1.0), Color(red: 0.9, green: 0.6, blue: 1.0)],
        [Color(red: 0.2, green: 0.78, blue: 0.65), Color(red: 0.4, green: 0.95, blue: 0.8)],
    ]

    public init(store: StoreOf<HomeFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    headerSection
                    mainContent
                }
            }
            .refreshable {
                await store.send(.refresh).finish()
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                generateButton
            }
            .toolbar(.hidden, for: .navigationBar)
            .background(alignment: .top) {
                Brand.pink
                    .frame(height: 1)
                    .ignoresSafeArea(edges: .top)
            }
        } destination: { store in
            switch store.case {
            case .courseGenerate(let store): CourseGenerateView(store: store)
            case .courseResult(let store): CourseResultView(store: store)
            case .settings(let store): SettingsView(store: store)
            case .partner(let store): PartnerView(store: store)
            case .anniversary(let store): AnniversaryView(store: store)
            }
        }
        .onAppear { store.send(.onAppear) }
        .alert($store.scope(state: \.alert, action: \.alert))
    }

    // MARK: - Header

    private var headerSection: some View {
        LinearGradient(
            colors: [Brand.pink, Color(red: 1.0, green: 0.6, blue: 0.4)],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: 120)
        .overlay(alignment: .bottom) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("안녕하세요, \(store.user.nickname)님")
                        .font(Typography.caption)
                        .foregroundStyle(.white.opacity(0.85))
                    Text("오늘 어디 갈까요?")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                }
                Spacer()
                Button {
                    store.send(.settingsTapped)
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.white)
                        .padding(9)
                        .background(.white.opacity(0.2))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.md)
        }
    }

    // MARK: - Main Content

    @ViewBuilder
    private var mainContent: some View {
        VStack(spacing: Spacing.xl) {
            if let anniversary = store.upcomingAnniversary {
                anniversaryBanner(anniversary)
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.lg)
            } else {
                Spacer().frame(height: Spacing.lg)
            }

            if store.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.top, Spacing.xxl)
            } else if store.recentCourses.isEmpty {
                emptyView
            } else {
                if !store.likedCourses.isEmpty {
                    likedCourseSection
                }
                courseSection
            }
        }
    }

    // MARK: - Anniversary Banner

    private func anniversaryBanner(_ anniversary: Anniversary) -> some View {
        let days = anniversary.daysUntilThisYear
        return HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(Brand.softPink)
                    .frame(width: 48, height: 48)
                Text(days == 0 ? "💕" : "🗓️")
                    .font(.system(size: 22))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(anniversary.name)
                    .font(Typography.body.weight(.semibold))
                Text(days == 0 ? "오늘이에요! 특별한 코스를 만들어봐요" : "D-\(days) 다가오고 있어요")
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if anniversary.yearsElapsed > 0 {
                Text("\(anniversary.yearsElapsed + 1)주년")
                    .font(Typography.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Brand.pink)
                    .clipShape(Capsule())
            }
        }
        .padding(Spacing.md)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Brand.softPink, lineWidth: 1.5)
        )
    }

    // MARK: - Liked Course Section

    private var likedCourseSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Label("마음에 든 코스", systemImage: "heart.fill")
                    .font(Typography.headline)
                    .foregroundStyle(.primary)
                    .labelStyle(TitleAndIconLabelStyle())
                Spacer()
            }
            .padding(.horizontal, Spacing.lg)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.md) {
                    ForEach(Array(store.likedCourses.enumerated()), id: \.element.id) { index, course in
                        Button {
                            store.send(.courseSelected(course))
                        } label: {
                            courseCard(course, gradientIndex: index, compact: true)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, 4)
                .padding(.bottom, 20)
            }
        }
    }

    // MARK: - Course Section

    private var courseSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("최근 코스")
                    .font(Typography.headline)
                Spacer()
                Text("\(store.recentCourses.count)개")
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, Spacing.lg)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.md) {
                    ForEach(Array(store.recentCourses.enumerated()), id: \.element.id) { index, course in
                        Button {
                            store.send(.courseSelected(course))
                        } label: {
                            courseCard(course, gradientIndex: index, compact: false)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, 4)
                .padding(.bottom, 20)
            }
        }
    }

    private func courseCard(_ course: Course, gradientIndex: Int, compact: Bool) -> some View {
        let gradient = courseGradients[gradientIndex % courseGradients.count]
        let cardWidth: CGFloat = compact ? 160 : 220
        let imageHeight: CGFloat = compact ? 90 : 120
        return VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                    .frame(height: imageHeight)

                VStack(alignment: .leading, spacing: 2) {
                    Text(course.title)
                        .font(Typography.headline)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text("\(course.places.count)곳")
                        .font(Typography.caption2)
                        .foregroundStyle(.white.opacity(0.85))
                }
                .padding(Spacing.md)

                if course.isLiked {
                    Image(systemName: "heart.fill")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(6)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .padding(Spacing.sm)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                }
            }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(course.places.compactMap { $0.placeName ?? $0.keyword }.prefix(3).joined(separator: " · "))
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                let formatter: DateFormatter = {
                    let f = DateFormatter()
                    f.locale = Locale(identifier: "ko_KR")
                    f.dateFormat = "M월 d일"
                    return f
                }()
                Text(formatter.string(from: course.date))
                    .font(Typography.caption2)
                    .foregroundStyle(Color(.tertiaryLabel))
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
        }
        .frame(width: cardWidth)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
    }

    // MARK: - Empty

    private var emptyView: some View {
        VStack(spacing: Spacing.lg) {
            ZStack {
                Circle()
                    .fill(Brand.softPink)
                    .frame(width: 100, height: 100)
                Text("💝")
                    .font(.system(size: 44))
            }
            VStack(spacing: Spacing.xs) {
                Text("첫 코스를 만들어봐요")
                    .font(Typography.headline)
                Text("아래 버튼을 눌러\n설레는 데이트 코스를 완성해보세요")
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    // MARK: - Generate Button

    private var generateButton: some View {
        Button {
            store.send(.generateCourseTapped)
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .semibold))
                Text("코스 만들기")
                    .font(Typography.body.weight(.bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(Brand.pink)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Brand.pink.opacity(0.3), radius: 10, x: 0, y: 4)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
        .background(.regularMaterial)
    }
}
