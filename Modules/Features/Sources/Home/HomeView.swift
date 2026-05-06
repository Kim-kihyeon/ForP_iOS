import SwiftUI
import ComposableArchitecture
import CoreSharedUI
import Domain

public struct HomeView: View {
    @Bindable var store: StoreOf<HomeFeature>
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var quickLocationFocused: Bool
    @State private var quickLocationText = ""

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
                .animation(.easeInOut(duration: 0.2), value: store.isEditingQuickLocation)
            }
            .refreshable {
                await store.send(.refresh).finish()
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                generateBottomBar
            }
            .toolbar(.hidden, for: .navigationBar)
            .background(Color(.systemBackground))
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
            case .partnerConnection(let store): PartnerConnectionView(store: store)
            }
        }
        .onAppear { store.send(.onAppear) }
        .alert($store.scope(state: \.alert, action: \.alert))
        .overlay {
            if store.isQuickGenerating {
                QuickGenerateLoadingOverlay(
                    themes: store.pendingQuickGenerateThemes,
                    onCancel: { store.send(.cancelQuickGenerate) }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .animation(.spring(response: 0.35), value: store.isQuickGenerating)
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
        .sheet(isPresented: Binding(
            get: { store.showFootprints },
            set: { if !$0 { store.send(.footprintsDismissed) } }
        )) {
            FootprintMapView(
                courses: store.footprintCourses,
                isLoading: store.isLoadingFootprints,
                onDismiss: { store.send(.footprintsDismissed) }
            )
        }
        .sheet(isPresented: Binding(
            get: { store.showCalendar },
            set: { if !$0 { store.send(.calendarDismissed) } }
        )) {
            CourseCalendarView(
                courses: store.recentCourses,
                anniversaries: store.allAnniversaries,
                onSelectCourse: { store.send(.calendarCourseSelected($0)) },
                onDismiss: { store.send(.calendarDismissed) }
            )
        }
    }

    // MARK: - Header

    private var todayDateString: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M월 d일 EEEE"
        return f.string(from: Date())
    }

    private var headerSection: some View {
        VStack(spacing: 18) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(todayDateString)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Brand.pink)
                    Text(store.user.nickname)
                        .font(.system(size: 22, weight: .bold))
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

            primaryHeroCard
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, 18)
        .padding(.bottom, Spacing.lg)
    }

    // MARK: - Content

    @ViewBuilder
    private var contentSection: some View {
        VStack(spacing: 18) {
            secondaryActionStrip
                .padding(.horizontal, Spacing.lg)

            if let course = store.inProgressCourse {
                inProgressCourseCard(course)
                    .padding(.horizontal, Spacing.lg)
            }

            if let anniversary = store.upcomingAnniversary {
                anniversaryCard(anniversary)
                    .padding(.horizontal, Spacing.lg)
            }

            if store.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
            } else if store.recentCourses.isEmpty && store.inProgressCourse == nil {
                emptyState
            } else {
                courseListSection
            }
        }
        .padding(.top, Spacing.sm)
        .padding(.bottom, 36)
    }

    // MARK: - Hero

    private var effectiveLocationName: String {
        if let override = store.quickLocationOverride {
            return override.placeName ?? override.keyword
        }
        return store.user.location.isEmpty ? "동네 설정" : store.user.location
    }

    private var primaryHeroCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 위치 선택 행
            HStack(spacing: 8) {
                Button {
                    Haptics.selection()
                    if store.isEditingQuickLocation {
                        store.send(.quickLocationEditDismissed)
                        quickLocationFocused = false
                    } else {
                        store.send(.quickLocationEditTapped)
                        quickLocationFocused = true
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 12))
                        Text(effectiveLocationName)
                            .font(.system(size: 13, weight: .semibold))
                            .lineLimit(1)
                        Image(systemName: store.isEditingQuickLocation ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(store.isEditingQuickLocation ? 0.3 : 0.2))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                if store.quickLocationOverride != nil && !store.isEditingQuickLocation {
                    Button {
                        Haptics.selection()
                        store.send(.quickLocationCleared)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
            }

            if store.isEditingQuickLocation {
                quickLocationSearchContent
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text("오늘 뭐 하지?")
                        .font(.system(size: 28, weight: .black))
                        .foregroundStyle(.white)
                    Text(heroSubtitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.75))
                        .lineLimit(2)
                }

                HStack(spacing: 8) {
                    ForEach(moodOptions, id: \.label) { mood in
                        moodChip(mood)
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.90, green: 0.15, blue: 0.35),
                        Brand.pink,
                        Color(red: 1.0, green: 0.58, blue: 0.38)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 140, height: 140)
                    .blur(radius: 20)
                    .offset(x: 80, y: -40)
                Circle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 100, height: 100)
                    .blur(radius: 16)
                    .offset(x: -30, y: 50)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color(red: 0.90, green: 0.15, blue: 0.35).opacity(0.35), radius: 18, x: 0, y: 8)
        .onChange(of: store.isEditingQuickLocation) { _, isEditing in
            if !isEditing { quickLocationText = "" }
        }
    }

    @ViewBuilder
    private var quickLocationSearchContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
                TextField(
                    "",
                    text: $quickLocationText,
                    prompt: Text("동네 이름으로 검색...").foregroundStyle(.white.opacity(0.5))
                )
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
                .focused($quickLocationFocused)
                .tint(.white)
                .onChange(of: quickLocationText) { _, newValue in
                    store.send(.quickLocationQueryChanged(newValue))
                }

                if store.isSearchingQuickLocation {
                    ProgressView().tint(.white).scaleEffect(0.75)
                } else if !quickLocationText.isEmpty {
                    Button {
                        quickLocationText = ""
                        store.send(.quickLocationQueryChanged(""))
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }

                Button("취소") {
                    store.send(.quickLocationEditDismissed)
                    quickLocationFocused = false
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.85))
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            if !store.quickLocationSuggestions.isEmpty {
                VStack(spacing: 0) {
                    ForEach(Array(store.quickLocationSuggestions.enumerated()), id: \.offset) { index, place in
                        Button {
                            Haptics.selection()
                            quickLocationText = ""
                            store.send(.quickLocationSuggestionSelected(place))
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Brand.pink)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(place.placeName ?? place.keyword)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                    if let address = place.address, !address.isEmpty {
                                        Text(address)
                                            .font(.system(size: 11))
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.plain)

                        if index < store.quickLocationSuggestions.count - 1 {
                            Divider().padding(.leading, 38)
                        }
                    }
                }
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
                .transition(.opacity.combined(with: .scale(scale: 0.97, anchor: .top)))
            } else if shouldShowQuickLocationNoResults {
                SearchNoResultsView(message: "동네 이름을 조금 다르게 입력해보세요")
                    .transition(.opacity.combined(with: .scale(scale: 0.97, anchor: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.18), value: store.quickLocationSuggestions.count)
    }

    private var shouldShowQuickLocationNoResults: Bool {
        store.quickLocationQuery.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2 &&
        !store.isSearchingQuickLocation &&
        store.quickLocationSuggestions.isEmpty
    }

    private var heroSubtitle: String {
        if let weather = store.weather {
            return "\(weather.temperature)° \(weather.condition), \(weatherHint(weather))"
        }
        return "지역과 분위기만 고르면 바로 추천해드릴게요"
    }

    private var secondaryActionStrip: some View {
        HStack(spacing: 8) {
            actionPill("리포트", systemImage: "chart.bar.fill", color: Brand.iconBlue) {
                store.send(.monthlyReportTapped)
            }
            actionPill("취향 지도", systemImage: "map.fill", color: Brand.iconGreen) {
                store.send(.tasteMapTapped)
            }
            actionPill("발자국", systemImage: "point.topleft.down.curvedto.point.bottomright.up", color: Brand.iconPurple) {
                store.send(.footprintsTapped)
            }
            actionPill("캘린더", systemImage: "calendar", color: Brand.iconOrange) {
                store.send(.calendarTapped)
            }
        }
    }

    private func actionPill(_ title: String, systemImage: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(color)
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(.separator).opacity(colorScheme == .dark ? 1.0 : 0.45), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Anniversary

    private func inProgressCourseCard(_ course: Course) -> some View {
        Button {
            Haptics.impact(.medium)
            store.send(.courseSelected(course))
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.white.opacity(0.22))
                        .frame(width: 52, height: 52)
                    Image(systemName: "figure.walk")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text("진행 중인 데이트")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.78))
                    Text(course.title)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text("\(course.visitedOrders.count)/\(course.places.count)곳 완료")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.78))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.75))
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: [Brand.pink, Color(red: 1.0, green: 0.58, blue: 0.38)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: Brand.pink.opacity(0.22), radius: 14, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }

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
        .background(Color(.secondarySystemBackground))
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

            if !store.displayRecentCourses.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                sectionLabel("최근 코스", systemImage: "clock", color: .secondary)
                    .padding(.horizontal, Spacing.lg)

                VStack(spacing: 8) {
                    ForEach(store.displayRecentCourses, id: \.id) { course in
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
                if let displayRating = course.averageRating {
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { i in
                            Image(systemName: Double(i) <= displayRating + 0.5 ? (Double(i) <= displayRating ? "star.fill" : "star.leadinghalf.filled") : "star")
                                .font(.system(size: 8))
                                .foregroundStyle(Double(i) <= displayRating + 0.5 ? Color.yellow : Color(.tertiaryLabel))
                        }
                    }
                    .padding(.top, 1)
                }
            }
            .padding(12)
        }
        .frame(width: 160, height: 126)
        .background(
            LinearGradient(
                colors: [Brand.softPink, Color(.secondarySystemBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay {
            if colorScheme == .dark {
                RoundedRectangle(cornerRadius: 18).stroke(Color(.separator), lineWidth: 1)
            }
        }
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
            VStack(spacing: 0) {
                Text(month)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Brand.pink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                    .background(Brand.pink.opacity(0.15))
                Text(day)
                    .font(.system(size: 22, weight: .black))
                    .foregroundStyle(.primary)
                    .padding(.vertical, 6)
            }
            .frame(width: 44)
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
                    if course.status == .inProgress {
                        Text("진행중")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Brand.pink)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Brand.softPink)
                            .clipShape(Capsule())
                    } else if course.isEnded {
                        Text("종료")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(.systemFill))
                            .clipShape(Capsule())
                    }
                    if course.userId != store.user.id {
                        Text("파트너")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Brand.iconBlue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Brand.iconBlue.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }

                Text(course.places.compactMap { $0.placeName ?? $0.keyword }.prefix(3).joined(separator: " · "))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if let displayRating = course.averageRating {
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { i in
                            Image(systemName: Double(i) <= displayRating + 0.5 ? (Double(i) <= displayRating ? "star.fill" : "star.leadinghalf.filled") : "star")
                                .font(.system(size: 9))
                                .foregroundStyle(Double(i) <= displayRating + 0.5 ? Color.yellow : Color(.tertiaryLabel))
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
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay {
            if colorScheme == .dark {
                RoundedRectangle(cornerRadius: 20).stroke(Color(.separator), lineWidth: 1)
            }
        }
        .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.04), radius: 6, x: 0, y: 2)
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(Brand.softPink)
                    .frame(width: 86, height: 86)
                Image(systemName: "map")
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(Brand.pink)
            }
            .padding(.top, 36)

            VStack(spacing: 7) {
                Text("아직 저장한 코스가 없어요")
                    .font(.system(size: 19, weight: .bold))
                Text("가볍게 하나 만들어두고\n마음에 안 드는 곳만 바꿔도 돼요")
                    .font(Typography.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                Haptics.impact(.medium)
                store.send(.generateCourseTapped)
            } label: {
                Text("첫 코스 만들기")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 12)
                    .background(Brand.pink)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Quick Mood

    private struct MoodOption {
        let emoji: String
        let label: String
        let color: Color
        let themes: [String]
    }

    private let moodOptions: [MoodOption] = [
        MoodOption(emoji: "✨", label: "감성", color: Brand.iconPurple, themes: ["감성", "인스타감성"]),
        MoodOption(emoji: "💕", label: "로맨틱", color: Brand.pink, themes: ["로맨틱", "분위기 있는"]),
        MoodOption(emoji: "⚡️", label: "액티브", color: Brand.iconOrange, themes: ["야외", "액티브"]),
        MoodOption(emoji: "🌿", label: "힐링", color: Brand.iconGreen, themes: ["조용한", "힐링"]),
    ]

    private func moodChip(_ mood: MoodOption) -> some View {
        Button {
            Haptics.impact(.medium)
            store.send(.quickGenerateTapped(mood.themes))
        } label: {
            VStack(spacing: 4) {
                Text(mood.emoji)
                    .font(.system(size: 20))
                Text(mood.label)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(Color.white.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(store.isQuickGenerating)
        .opacity(store.isQuickGenerating ? 0.5 : 1)
    }

    // MARK: - Bottom Bar

    private var generateBottomBar: some View {
        Button {
            Haptics.impact(.medium)
            store.send(.generateCourseTapped)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 15, weight: .semibold))
                Text("코스 만들기")
                    .font(.system(size: 16, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Brand.pink)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Brand.pink.opacity(0.3), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
        .background(.regularMaterial)
    }

    // MARK: - Helpers

    private func weatherHint(_ weather: WeatherInfo) -> String {
        if weather.condition.contains("비") || weather.condition.contains("rain") { return "실내 코스 어때요?" }
        if weather.condition.contains("눈") || weather.condition.contains("snow") { return "눈 오는 날 특별한 데이트" }
        if weather.temperature >= 28 { return "시원한 실내 코스 추천" }
        if weather.temperature <= 3 { return "따뜻한 실내 데이트 어때요?" }
        if weather.temperature >= 18 { return "야외 데이트 딱 좋은 날씨" }
        return "선선한 날씨, 산책 코스 어때요?"
    }
}

// MARK: - Quick Generate Loading Overlay

private struct QuickGenerateLoadingOverlay: View {
    let themes: [String]
    let onCancel: () -> Void

    @State private var pulseScale: CGFloat = 1.0
    @State private var dotOffsets: [CGFloat] = [0, 0, 0]
    @State private var glowOpacity: Double = 0.3

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .background(.ultraThinMaterial)

            VStack(spacing: 30) {
                // 아이콘 + 링 애니메이션
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.07))
                        .frame(width: 136, height: 136)
                        .scaleEffect(pulseScale)
                    Circle()
                        .fill(Color.white.opacity(0.11))
                        .frame(width: 104, height: 104)
                        .scaleEffect(pulseScale * 0.97)
                    Circle()
                        .fill(Color.white.opacity(0.18))
                        .frame(width: 76, height: 76)
                    Image(systemName: "sparkles")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(.white)
                        .symbolEffect(.pulse.wholeSymbol)
                }

                VStack(spacing: 10) {
                    // 선택한 무드 태그
                    if !themes.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(themes.prefix(3), id: \.self) { theme in
                                Text(theme)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.white.opacity(0.22))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    Text("코스 만드는 중")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                    Text("AI가 딱 맞는 장소를 고르고 있어요")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.78))
                }

                // 바운싱 도트
                HStack(spacing: 10) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(Color.white)
                            .frame(width: 7, height: 7)
                            .offset(y: dotOffsets[i])
                    }
                }

                Button(action: onCancel) {
                    Text("취소")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.18))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(40)
            .frame(maxWidth: 320)
            .background(
                ZStack {
                    LinearGradient(
                        colors: [
                            Color(red: 0.90, green: 0.15, blue: 0.35),
                            Brand.pink,
                            Color(red: 1.0, green: 0.58, blue: 0.38)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 200)
                        .blur(radius: 50)
                        .offset(x: 60, y: -60)
                    Circle()
                        .fill(Color.white.opacity(glowOpacity))
                        .frame(width: 120)
                        .blur(radius: 30)
                        .offset(x: -50, y: 60)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 32))
            .shadow(
                color: Color(red: 0.90, green: 0.15, blue: 0.35).opacity(0.5),
                radius: 48, x: 0, y: 20
            )
            .padding(.horizontal, 32)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                pulseScale = 1.1
            }
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                glowOpacity = 0.08
            }
            for i in 0..<3 {
                withAnimation(
                    .easeInOut(duration: 0.55)
                    .repeatForever(autoreverses: true)
                    .delay(Double(i) * 0.18)
                ) {
                    dotOffsets[i] = -7
                }
            }
        }
    }
}
