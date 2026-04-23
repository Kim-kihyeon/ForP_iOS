import SwiftUI
import ComposableArchitecture
import CoreSharedUI
import Domain

public struct HomeView: View {
    @Bindable var store: StoreOf<HomeFeature>
    @Environment(\.colorScheme) private var colorScheme

    public init(store: StoreOf<HomeFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    headerSection
                    contentSection
                }
            }
            .refreshable {
                await store.send(.refresh).finish()
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                generateButton
            }
            .toolbar(.hidden, for: .navigationBar)
            .background(Color(.systemGroupedBackground))
        } destination: { store in
            switch store.case {
            case .courseGenerate(let store): CourseGenerateView(store: store)
            case .courseResult(let store): CourseResultView(store: store)
            case .settings(let store): SettingsView(store: store)
            case .partner(let store): PartnerView(store: store)
            case .anniversary(let store): AnniversaryView(store: store)
            case .profile(let store): ProfileView(store: store)
            case .wishlist(let store): WishlistManageView(store: store)
            case .defaultChecklist: DefaultChecklistManageView()
            }
        }
        .onAppear { store.send(.onAppear) }
        .alert($store.scope(state: \.alert, action: \.alert))
        .sheet(isPresented: Binding(
            get: { store.showMonthlyReport },
            set: { if !$0 { store.send(.monthlyReportDismissed) } }
        )) {
            MonthlyReportView(
                courses: store.monthlyCourses,
                isLoading: store.isLoadingMonthly,
                onDismiss: { store.send(.monthlyReportDismissed) }
            )
        }
        .sheet(isPresented: Binding(
            get: { store.showTasteMap },
            set: { if !$0 { store.send(.tasteMapDismissed) } }
        )) {
            TasteMapView(
                courses: store.recentCourses,
                user: store.user,
                onDismiss: { store.send(.tasteMapDismissed) }
            )
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("안녕하세요,")
                        .font(Typography.caption)
                        .foregroundStyle(.secondary)
                    Text(store.user.nickname)
                        .font(.system(size: 26, weight: .bold, design: .default))
                }
                Spacer()
                Button {
                    store.send(.settingsTapped)
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(width: 38, height: 38)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, 16)
            .padding(.bottom, 10)

            Group {
                if let weather = store.weather {
                    weatherStrip(weather)
                } else {
                    Capsule()
                        .fill(Color(.tertiarySystemFill))
                        .frame(width: 180, height: 14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.md)
        }
        .background(Color(.systemBackground))
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    private func weatherStrip(_ weather: WeatherInfo) -> some View {
        HStack(spacing: 8) {
            Text(weatherEmoji(weather.condition))
                .font(.system(size: 14))
            Text("\(weather.temperature)°")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Brand.pink)
            Text(weather.condition)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            Text("·")
                .foregroundStyle(Color(.tertiaryLabel))
            Text(weatherHint(weather))
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color(.secondarySystemBackground))
        .clipShape(Capsule())
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Content

    @ViewBuilder
    private var contentSection: some View {
        VStack(spacing: 0) {
            if let anniversary = store.upcomingAnniversary {
                anniversaryCard(anniversary)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.lg)
                    .padding(.bottom, Spacing.sm)
            }

            monthlyReportBanner
                .padding(.horizontal, Spacing.lg)
                .padding(.top, store.upcomingAnniversary == nil ? Spacing.lg : Spacing.sm)
                .padding(.bottom, Spacing.sm)

            if store.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.top, 80)
            } else if store.recentCourses.isEmpty {
                emptyState
            } else {
                courseListSection
            }
        }
        .padding(.bottom, 100)
    }

    // MARK: - Monthly Report Banner

    private var monthlyReportBanner: some View {
        let month = Calendar.current.component(.month, from: Date())
        return Button {
            store.send(.monthlyReportTapped)
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Brand.pink.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Brand.pink)
                }
                Text("\(month)월 데이트 리포트 보기")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(.tertiaryLabel))
            }
            .padding(12)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(.separator).opacity(colorScheme == .dark ? 1.0 : 0.5), lineWidth: 0.5))
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.04), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Anniversary

    private func anniversaryCard(_ anniversary: Anniversary) -> some View {
        let days = anniversary.daysUntilThisYear
        return HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Brand.softPink)
                    .frame(width: 52, height: 52)
                Text(days == 0 ? "💕" : "🗓️")
                    .font(.system(size: 24))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(anniversary.name)
                    .font(Typography.body.weight(.semibold))
                Text(days == 0 ? "오늘이에요! 특별한 코스를 만들어봐요" : "D-\(days)  다가오고 있어요")
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if anniversary.yearsElapsed > 0 {
                VStack(spacing: 1) {
                    Text("\(anniversary.yearsElapsed + 1)")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Brand.pink)
                    Text("주년")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Brand.softPink, lineWidth: 1.5)
        )
        .shadow(color: Brand.pink.opacity(0.08), radius: 12, x: 0, y: 4)
    }

    // MARK: - Course List

    private var courseListSection: some View {
        VStack(spacing: 0) {
            if !store.likedCourses.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    sectionLabel("즐겨찾는 코스", systemImage: "heart.fill", color: Brand.pink)
                        .padding(.horizontal, Spacing.lg)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(store.likedCourses, id: \.id) { course in
                                Button {
                                    store.send(.courseSelected(course))
                                } label: {
                                    favoriteCourseCard(course)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, Spacing.lg)
                        .padding(.bottom, 4)
                    }
                }
                .padding(.top, Spacing.lg)
                .padding(.bottom, Spacing.xl)
            }

            VStack(alignment: .leading, spacing: 10) {
                sectionLabel("최근 코스", systemImage: "clock", color: .secondary)
                    .padding(.horizontal, Spacing.lg)

                VStack(spacing: 8) {
                    ForEach(store.recentCourses, id: \.id) { course in
                        Button {
                            store.send(.courseSelected(course))
                        } label: {
                            recentCourseRow(course)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, Spacing.lg)
                    }
                }
            }
            .padding(.top, store.likedCourses.isEmpty ? Spacing.lg : 0)
        }
    }

    private func sectionLabel(_ title: String, systemImage: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(color)
            Text(title)
                .font(.system(size: 15, weight: .semibold))
        }
    }

    // MARK: - Favorite Card (horizontal scroll)

    private func favoriteCourseCard(_ course: Course) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer()
                Image(systemName: "heart.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(Brand.pink)
                    .padding(7)
                    .background(Brand.softPink)
                    .clipShape(Circle())
            }
            .padding([.top, .trailing], 10)

            Spacer()

            VStack(alignment: .leading, spacing: 3) {
                Text(course.title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(course.places.compactMap { $0.placeName ?? $0.keyword }.prefix(2).joined(separator: " · "))
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                if let rating = course.rating {
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { i in
                            Image(systemName: i <= rating ? "star.fill" : "star")
                                .font(.system(size: 8))
                                .foregroundStyle(i <= rating ? Color.yellow : Color(.tertiaryLabel))
                        }
                    }
                    .padding(.top, 1)
                }
            }
            .padding(12)
        }
        .frame(width: 160, height: 110)
        .background(
            LinearGradient(
                colors: [Brand.softPink.opacity(0.35), Color(.systemBackground)],
                startPoint: .top,
                endPoint: .center
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color(.separator).opacity(colorScheme == .dark ? 1.0 : 0.5), lineWidth: colorScheme == .dark ? 1.0 : 0.5))
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.4 : 0.06), radius: 8, x: 0, y: 2)
    }

    // MARK: - Recent Course Row

    private func recentCourseRow(_ course: Course) -> some View {
        let month: String = {
            let f = DateFormatter()
            f.locale = Locale(identifier: "ko_KR")
            f.dateFormat = "MMM"
            return f.string(from: course.date)
        }()
        let day: String = {
            let f = DateFormatter()
            f.dateFormat = "d"
            return f.string(from: course.date)
        }()

        return HStack(spacing: 14) {
            // 날짜 배지
            VStack(spacing: 1) {
                Text(month)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Brand.pink)
                Text(day)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.primary)
            }
            .frame(width: 44, height: 52)
            .background(Brand.softPink)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline) {
                    Text(course.title)
                        .font(.system(size: 15, weight: .semibold))
                        .lineLimit(1)
                    if course.isLiked {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Brand.pink)
                    }
                }

                Text(course.places.compactMap { $0.placeName ?? $0.keyword }.prefix(3).joined(separator: " · "))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if let rating = course.rating {
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { i in
                            Image(systemName: i <= rating ? "star.fill" : "star")
                                .font(.system(size: 9))
                                .foregroundStyle(i <= rating ? Color.yellow : Color(.tertiaryLabel))
                        }
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color(.tertiaryLabel))
        }
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(.separator).opacity(colorScheme == .dark ? 1.0 : 0.5), lineWidth: colorScheme == .dark ? 1.0 : 0.5))
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(spacing: 0) {
            // 일러스트 영역
            ZStack {
                Circle()
                    .fill(Brand.softPink)
                    .frame(width: 96, height: 96)
                Image(systemName: "sparkles")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(Brand.pink)
            }
            .padding(.top, 56)
            .padding(.bottom, 24)

            VStack(spacing: 8) {
                Text("첫 데이트 코스를 만들어봐요")
                    .font(.system(size: 20, weight: .bold))
                Text("AI가 날씨, 취향, 동선까지\n완벽한 코스를 짜드려요")
                    .font(Typography.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, 32)

            VStack(spacing: 14) {
                emptyFeatureRow("location.fill", color: Brand.pink, text: "지역과 테마를 선택하면")
                emptyFeatureRow("sparkles", color: Brand.iconOrange, text: "AI가 실제 장소를 추천해줘요")
                emptyFeatureRow("map.fill", color: Brand.iconBlue, text: "동선까지 자동으로 최적화해줘요")
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity)
    }

    private func emptyFeatureRow(_ icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(color)
            }
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.primary)
            Spacer()
        }
    }

    // MARK: - Generate Button

    private var generateButton: some View {
        VStack(spacing: 0) {
            Divider().opacity(0.4)
            Button {
                Haptics.impact(.medium)
                store.send(.generateCourseTapped)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 15, weight: .semibold))
                    Text("코스 만들기")
                        .font(.system(size: 16, weight: .bold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Brand.pink)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Brand.pink.opacity(0.35), radius: 12, x: 0, y: 4)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, 10)
            .padding(.bottom, Spacing.lg)
            .background(.ultraThinMaterial)
        }
    }

    // MARK: - Helpers

    private func weatherEmoji(_ condition: String) -> String {
        if condition.contains("비") || condition.contains("rain") { return "🌧️" }
        if condition.contains("눈") || condition.contains("snow") { return "❄️" }
        if condition.contains("흐림") || condition.contains("cloud") || condition.contains("구름") { return "☁️" }
        return "☀️"
    }

    private func weatherHint(_ weather: WeatherInfo) -> String {
        if weather.condition.contains("비") || weather.condition.contains("rain") { return "실내 코스 어때요?" }
        if weather.condition.contains("눈") || weather.condition.contains("snow") { return "눈 오는 날 특별한 데이트" }
        if weather.temperature >= 28 { return "시원한 실내 코스 추천" }
        if weather.temperature <= 3 { return "따뜻한 실내 데이트 어때요?" }
        if weather.temperature >= 18 { return "야외 데이트 딱 좋은 날씨" }
        return "선선한 날씨, 산책 코스 어때요?"
    }
}
