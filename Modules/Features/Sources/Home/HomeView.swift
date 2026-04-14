import SwiftUI
import ComposableArchitecture
import CoreSharedUI
import Domain

public struct HomeView: View {
    @Bindable var store: StoreOf<HomeFeature>

    public init(store: StoreOf<HomeFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            ZStack(alignment: .bottomTrailing) {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        headerSection
                        if let anniversary = store.upcomingAnniversary {
                            anniversaryCard(anniversary)
                                .padding(.horizontal, Spacing.md)
                        }
                        contentSection
                    }
                    .padding(.bottom, 88)
                }

                generateButton
            }
            .navigationBarHidden(true)
        } destination: { store in
            switch store.case {
            case .courseGenerate(let store):
                CourseGenerateView(store: store)
            case .courseResult(let store):
                CourseResultView(store: store)
            case .settings(let store):
                SettingsView(store: store)
            case .partner(let store):
                PartnerView(store: store)
            case .anniversary(let store):
                AnniversaryView(store: store)
            }
        }
        .onAppear { store.send(.onAppear) }
        .alert($store.scope(state: \.alert, action: \.alert))
    }

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("안녕하세요")
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)
                Text("\(store.user.nickname)님의 코스")
                    .font(Typography.largeTitle)
            }

            Spacer()

            Button {
                store.send(.settingsTapped)
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.secondary)
                    .padding(Spacing.sm)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.lg + Spacing.sm)
    }

    @ViewBuilder
    private var contentSection: some View {
        if store.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.top, Spacing.xxl)
        } else if store.recentCourses.isEmpty {
            emptyView
        } else {
            courseList
        }
    }

    private var emptyView: some View {
        VStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(Brand.softPink)
                    .frame(width: 88, height: 88)
                Image(systemName: "map.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Brand.pink)
            }
            Text("아직 만든 코스가 없어요")
                .font(Typography.headline)
            Text("하단 버튼을 눌러 첫 코스를 만들어보세요")
                .font(Typography.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 72)
        .padding(.horizontal, Spacing.md)
    }

    private var courseList: some View {
        LazyVStack(spacing: Spacing.sm) {
            ForEach(store.recentCourses) { course in
                Button {
                    store.send(.courseSelected(course))
                } label: {
                    courseCard(course)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Spacing.md)
    }

    private func courseCard(_ course: Course) -> some View {
        HStack(spacing: Spacing.md) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Brand.pink)
                .frame(width: 3, height: 44)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(course.title)
                    .font(Typography.headline)
                    .foregroundStyle(.primary)
                Text(course.places.map { $0.placeName ?? $0.keyword }.joined(separator: " → "))
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(Spacing.md)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    private func anniversaryCard(_ anniversary: Anniversary) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "heart.fill")
                .font(.title2)
                .foregroundStyle(Brand.pink)

            VStack(alignment: .leading, spacing: 2) {
                Text(anniversary.name)
                    .font(Typography.body.weight(.semibold))
                let days = anniversary.daysUntilThisYear
                Text(days == 0 ? "오늘이에요!" : "D-\(days)")
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if anniversary.yearsElapsed > 0 {
                Text("\(anniversary.yearsElapsed + 1)주년")
                    .font(Typography.caption.weight(.semibold))
                    .foregroundStyle(Brand.pink)
            }
        }
        .padding(Spacing.md)
        .background(Brand.softPink)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var generateButton: some View {
        Button {
            store.send(.generateCourseTapped)
        } label: {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "sparkles")
                Text("코스 만들기")
                    .font(Typography.body.weight(.semibold))
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm + 4)
            .background(Brand.pink)
            .foregroundStyle(.white)
            .clipShape(Capsule())
            .shadow(color: Brand.pink.opacity(0.4), radius: 10, x: 0, y: 4)
        }
        .padding(.trailing, Spacing.md)
        .padding(.bottom, Spacing.lg + Spacing.sm)
    }
}
