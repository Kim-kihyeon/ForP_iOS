import ComposableArchitecture
import Domain
import Foundation

@Reducer
public struct HomeFeature {
    @Reducer
    public enum Path {
        case courseGenerate(CourseGenerateFeature)
        case courseResult(CourseResultFeature)
        case settings(SettingsFeature)
        case partner(PartnerFeature)
        case anniversary(AnniversaryFeature)
        case profile(ProfileFeature)
        case wishlist(WishlistManageFeature)
        case defaultChecklist
        case partnerConnection(PartnerConnectionFeature)
    }

    @ObservableState
    public struct State: Equatable {
        public var user: User
        public var path = StackState<Path.State>()
        public var partner: Partner? = nil
        public var recentCourses: [Course] = []
        public var likedCourses: [Course] { recentCourses.filter { $0.isLiked } }
        public var inProgressCourse: Course? = nil
        public var displayRecentCourses: [Course] {
            recentCourses.filter { $0.id != inProgressCourse?.id }
        }
        public var upcomingAnniversary: Anniversary? = nil
        public var allAnniversaries: [Anniversary] = []
        public var weather: WeatherInfo? = nil
        public var isLoading = false
        public var showMonthlyReport = false
        public var monthlyCourses: [Course] = []
        public var isLoadingMonthly = false
        public var showTasteMap = false
        public var showFootprints = false
        public var footprintCourses: [Course] = []
        public var isLoadingFootprints = false
        public var showCalendar = false
        public var isQuickGenerating = false
        public var pendingQuickGenerateThemes: [String] = []
        public var isEditingQuickLocation = false
        public var quickLocationQuery = ""
        public var quickLocationSuggestions: [CoursePlace] = []
        public var isSearchingQuickLocation = false
        public var quickLocationOverride: CoursePlace? = nil
        @Presents public var alert: AlertState<Action.Alert>?

        public init(user: User) {
            self.user = user
        }
    }

    public enum Action {
        case path(StackActionOf<Path>)
        case onAppear
        case refresh
        case loadCoursesResponse(Result<[Course], Error>)
        case loadInProgressCourseResponse(Result<Course?, Error>)
        case loadPartnerResponse(Result<Partner?, Error>)
        case loadAnniversariesResponse(Result<[Anniversary], Error>)
        case loadWeatherResponse(Result<WeatherInfo, Error>)
        case generateCourseTapped
        case quickGenerateTapped([String])
        case quickGenerateResponse(Result<CoursePlan, Error>)
        case quickCourseReadyToShow(Course, CourseOptions)
        case cancelQuickGenerate
        case quickLocationEditTapped
        case quickLocationQueryChanged(String)
        case quickLocationSearchDebounced
        case quickLocationSuggestionsLoaded([CoursePlace])
        case quickLocationSuggestionSelected(CoursePlace)
        case quickLocationCleared
        case quickLocationEditDismissed
        case courseReadyToShow(Course, String?, CourseOptions)
        case redateCourseReady(Course)
        case courseSelected(Course)
        case settingsTapped
        case monthlyReportTapped
        case monthlyReportDismissed
        case loadMonthlyCoursesResponse(Result<[Course], Error>)
        case tasteMapTapped
        case tasteMapDismissed
        case footprintsTapped
        case footprintsDismissed
        case loadFootprintCoursesResponse(Result<[Course], Error>)
        case calendarTapped
        case calendarDismissed
        case calendarCourseSelected(Course)
        case alert(PresentationAction<Alert>)
        case delegate(Delegate)

        public enum Alert: Equatable {}
        public enum Delegate: Equatable {
            case loggedOut
        }
    }

    @Dependency(\.fetchRecentCoursesUseCase) var fetchRecentCoursesUseCase
    @Dependency(\.fetchEffectivePartnerUseCase) var fetchEffectivePartnerUseCase
    @Dependency(\.partnerConnectionRepository) var partnerConnectionRepository
    @Dependency(\.anniversaryRepository) var anniversaryRepository
    @Dependency(\.notificationService) var notificationService: any NotificationServiceProtocol
    @Dependency(\.notificationSettingsStore) var notificationSettingsStore
    @Dependency(\.weatherService) var weatherService: any WeatherServiceProtocol
    @Dependency(\.placeRepository) var placeRepository
    @Dependency(\.courseRepository) var courseRepository: any CourseRepositoryProtocol
    @Dependency(\.generateCourseUseCase) var generateCourseUseCase

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                let shouldLoadCourses = state.recentCourses.isEmpty
                let shouldLoadPartner = state.partner == nil
                let shouldLoadWeather = state.weather == nil
                state.isLoading = shouldLoadCourses
                let userLocation = state.user.location
                return .run { [userId = state.user.id] send in
                    if shouldLoadCourses {
                        await send(.loadCoursesResponse(
                            Result { try await fetchRecentCoursesUseCase.execute(userId: userId) }
                        ))
                    }
                    await send(.loadInProgressCourseResponse(
                        Result { try await courseRepository.fetchInProgressCourse(userId: userId) }
                    ))
                    if shouldLoadPartner {
                        await send(.loadPartnerResponse(Result {
                            try await fetchEffectivePartnerUseCase.execute(userId: userId)
                        }))
                    }
                    // 기념일은 AnniversaryView 변경사항 반영을 위해 항상 갱신
                    await send(.loadAnniversariesResponse(
                        Result { try await anniversaryRepository.fetchAnniversaries(userId: userId) }
                    ))
                    if shouldLoadWeather {
                        let coord: (Double, Double)
                        if let place = try? await placeRepository.searchPlaces(keyword: userLocation).first,
                           let lat = place.latitude, let lon = place.longitude {
                            coord = (lat, lon)
                        } else {
                            coord = (37.5665, 126.9780)
                        }
                        await send(.loadWeatherResponse(
                            Result { try await weatherService.fetchWeather(latitude: coord.0, longitude: coord.1, date: Date()) }
                        ))
                    }
                }

            case .refresh:
                return .run { [userId = state.user.id] send in
                    await send(.loadCoursesResponse(
                        Result { try await fetchRecentCoursesUseCase.execute(userId: userId) }
                    ))
                    await send(.loadInProgressCourseResponse(
                        Result { try await courseRepository.fetchInProgressCourse(userId: userId) }
                    ))
                    await send(.loadAnniversariesResponse(
                        Result { try await anniversaryRepository.fetchAnniversaries(userId: userId) }
                    ))
                }

            case .loadCoursesResponse(.success(let courses)):
                state.isLoading = false
                state.recentCourses = courses
                return .none

            case .loadInProgressCourseResponse(.success(let course)):
                state.inProgressCourse = course
                return .none

            case .loadInProgressCourseResponse(.failure):
                return .none

            case .loadPartnerResponse(.success(let partner)):
                state.partner = partner
                return .none

            case .loadPartnerResponse(.failure(let error)):
                print("[HomeFeature] loadPartnerResponse failed: \(error)")
                return .none

            case .loadAnniversariesResponse(.success(let anniversaries)):
                state.allAnniversaries = anniversaries
                state.upcomingAnniversary = anniversaries.sorted { $0.daysUntilThisYear < $1.daysUntilThisYear }.first
                let anniversariesCopy = anniversaries
                return .run { _ in
                    let settings = notificationSettingsStore.load()
                    guard settings.pushEnabled, settings.anniversaryEnabled else { return }
                    await notificationService.scheduleAnniversaryNotifications(for: anniversariesCopy)
                }

            case .loadWeatherResponse(.success(let weather)):
                state.weather = weather
                return .none

            case .loadWeatherResponse(.failure):
                return .none

            case .loadAnniversariesResponse(.failure):
                return .none

            case .loadCoursesResponse(.failure(let error)):
                state.isLoading = false
                state.alert = AlertState { TextState("오류") } actions: { ButtonState(role: .cancel) { TextState("확인") } } message: { TextState(error.localizedDescription) }
                return .none

            case .monthlyReportTapped:
                let cal = Calendar.current
                let now = Date()
                let year = cal.component(.year, from: now)
                let month = cal.component(.month, from: now)
                state.showMonthlyReport = true
                state.isLoadingMonthly = true
                return .run { [userId = state.user.id] send in
                    await send(.loadMonthlyCoursesResponse(
                        Result { try await courseRepository.fetchCoursesByMonth(userId: userId, year: year, month: month) }
                    ))
                }

            case .monthlyReportDismissed:
                state.showMonthlyReport = false
                return .none

            case .loadMonthlyCoursesResponse(.success(let courses)):
                state.isLoadingMonthly = false
                state.monthlyCourses = courses
                return .none

            case .loadMonthlyCoursesResponse(.failure):
                state.isLoadingMonthly = false
                return .none

            case .tasteMapTapped:
                state.showTasteMap = true
                return .none

            case .tasteMapDismissed:
                state.showTasteMap = false
                return .none

            case .footprintsTapped:
                state.showFootprints = true
                state.isLoadingFootprints = true
                return .run { [userId = state.user.id] send in
                    await send(.loadFootprintCoursesResponse(
                        Result { try await fetchRecentCoursesUseCase.execute(userId: userId, limit: 80) }
                    ))
                }

            case .footprintsDismissed:
                state.showFootprints = false
                return .none

            case .loadFootprintCoursesResponse(.success(let courses)):
                state.isLoadingFootprints = false
                state.footprintCourses = courses
                return .none

            case .loadFootprintCoursesResponse(.failure):
                state.isLoadingFootprints = false
                return .none

            case .calendarTapped:
                state.showCalendar = true
                return .none

            case .calendarDismissed:
                state.showCalendar = false
                return .none

            case .calendarCourseSelected(let course):
                state.showCalendar = false
                state.path.append(.courseResult(CourseResultFeature.State(course: course, isSaved: true, user: state.user, partner: state.partner)))
                return .none

            case .alert:
                return .none

            case .generateCourseTapped:
                let learned = state.recentCourses.learnedPreferences()
                state.path.append(.courseGenerate(CourseGenerateFeature.State(
                    user: state.user,
                    partner: state.partner,
                    learnedPreferences: learned.isEmpty ? nil : learned
                )))
                return .none

            case .quickGenerateTapped(let themes):
                guard !state.isQuickGenerating else { return .none }
                let overridePlace = state.quickLocationOverride
                let rawLocation = overridePlace.flatMap { $0.placeName ?? $0.keyword }
                    ?? state.user.location
                let location = rawLocation.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !location.isEmpty else {
                    state.isEditingQuickLocation = true
                    return .none
                }
                state.isQuickGenerating = true
                state.isEditingQuickLocation = false
                state.pendingQuickGenerateThemes = themes
                let learned = state.recentCourses.learnedPreferences()
                let options = CourseOptions(
                    location: location,
                    themes: themes,
                    placeCount: 3,
                    mode: .ordered,
                    baseLatitude: overridePlace?.latitude,
                    baseLongitude: overridePlace?.longitude,
                    learnedPreferences: learned.isEmpty ? nil : learned
                )
                return .run { [user = state.user, partner = state.partner] send in
                    await send(.quickGenerateResponse(
                        Result { try await generateCourseUseCase.execute(user: user, partner: partner, options: options) }
                    ))
                }
                .cancellable(id: "quickCourseGeneration", cancelInFlight: true)

            case .quickGenerateResponse(.success(let plan)):
                state.isQuickGenerating = false
                let userId = state.user.id
                let existingPartnerId = state.partner?.userId
                let themes = state.pendingQuickGenerateThemes
                let location = state.user.location
                return .run { send in
                    let partnerId: UUID?
                    if let existing = existingPartnerId {
                        partnerId = existing
                    } else if let conn = try? await partnerConnectionRepository.fetchConnection(userId: userId) {
                        partnerId = conn.partnerId(myUserId: userId)
                    } else {
                        partnerId = nil
                    }
                    let title = themes.isEmpty ? "\(location) 데이트" : "\(themes.joined(separator: "·")) \(location) 데이트"
                    let course = Course(
                        userId: userId,
                        partnerId: partnerId,
                        title: title,
                        mode: .ordered,
                        places: plan.places,
                        candidates: plan.candidates,
                        outfitSuggestion: plan.outfitSuggestion,
                        courseReason: plan.courseReason
                    )
                    let options = CourseOptions(location: location, themes: themes, placeCount: 3, mode: .ordered)
                    await send(.quickCourseReadyToShow(course, options))
                }

            case .quickGenerateResponse(.failure(let error)):
                state.isQuickGenerating = false
                state.alert = AlertState { TextState("코스 생성 실패") } actions: { ButtonState(role: .cancel) { TextState("확인") } } message: { TextState(error.localizedDescription) }
                return .none

            case .cancelQuickGenerate:
                state.isQuickGenerating = false
                state.pendingQuickGenerateThemes = []
                return .cancel(id: "quickCourseGeneration")

            case .quickLocationEditTapped:
                state.isEditingQuickLocation = true
                state.quickLocationQuery = ""
                state.quickLocationSuggestions = []
                return .none

            case .quickLocationQueryChanged(let query):
                state.quickLocationQuery = query
                state.quickLocationSuggestions = []
                guard query.count >= 2 else {
                    state.isSearchingQuickLocation = false
                    return .cancel(id: "quickLocationSearch")
                }
                state.isSearchingQuickLocation = true
                return .run { send in
                    try? await Task.sleep(nanoseconds: 350_000_000)
                    await send(.quickLocationSearchDebounced)
                }
                .cancellable(id: "quickLocationSearch", cancelInFlight: true)

            case .quickLocationSearchDebounced:
                let query = state.quickLocationQuery
                return .run { [placeRepository] send in
                    let results = (try? await placeRepository.searchPlaces(keyword: query)) ?? []
                    await send(.quickLocationSuggestionsLoaded(results))
                }

            case .quickLocationSuggestionsLoaded(let places):
                state.isSearchingQuickLocation = false
                state.quickLocationSuggestions = Array(places.prefix(5))
                return .none

            case .quickLocationSuggestionSelected(let place):
                state.quickLocationOverride = place
                state.isEditingQuickLocation = false
                state.quickLocationQuery = ""
                state.quickLocationSuggestions = []
                return .cancel(id: "quickLocationSearch")

            case .quickLocationCleared:
                state.quickLocationOverride = nil
                return .none

            case .quickLocationEditDismissed:
                state.isEditingQuickLocation = false
                state.quickLocationQuery = ""
                state.quickLocationSuggestions = []
                return .cancel(id: "quickLocationSearch")

            case .quickCourseReadyToShow(let course, let options):
                state.pendingQuickGenerateThemes = []
                var resultState = CourseResultFeature.State(
                    course: course,
                    user: state.user,
                    partner: state.partner,
                    generationOptions: options
                )
                resultState.placeCountNote = course.places.count < options.placeCount
                    ? course.candidates.isEmpty
                        ? "요청한 \(options.placeCount)곳 중 \(course.places.count)곳만 찾았어요. 해당 지역에서 장소를 충분히 찾지 못했어요."
                        : "요청한 \(options.placeCount)곳 중 \(course.places.count)곳만 찾았어요. 후보 장소에서 추가할 수 있어요."
                    : nil
                state.path.append(.courseResult(resultState))
                return .none

            case .courseSelected(let course):
                state.path.append(.courseResult(CourseResultFeature.State(course: course, isSaved: true, user: state.user, partner: state.partner)))
                return .none

            case .settingsTapped:
                state.path.append(.settings(SettingsFeature.State()))
                return .none

            case .path(.element(_, action: .courseGenerate(.delegate(.courseGenerated(let plan, let options))))):
                let userId = state.user.id
                let existingPartnerId = state.partner?.userId
                return .run { send in
                    let partnerId: UUID?
                    if let existing = existingPartnerId {
                        partnerId = existing
                    } else if let conn = try? await partnerConnectionRepository.fetchConnection(userId: userId) {
                        partnerId = conn.partnerId(myUserId: userId)
                    } else {
                        partnerId = nil
                    }
                    let course = Course(
                        userId: userId,
                        partnerId: partnerId,
                        title: "\(options.location) 데이트",
                        mode: options.mode,
                        places: plan.places,
                        candidates: plan.candidates,
                        outfitSuggestion: plan.outfitSuggestion,
                        courseReason: plan.courseReason
                    )
                    let note: String? = plan.places.count < options.placeCount
                        ? plan.candidates.isEmpty
                            ? "요청한 \(options.placeCount)곳 중 \(plan.places.count)곳만 찾았어요. 해당 지역에서 장소를 충분히 찾지 못했어요."
                            : "요청한 \(options.placeCount)곳 중 \(plan.places.count)곳만 찾았어요. 후보 장소에서 추가할 수 있어요."
                        : nil
                    await send(.courseReadyToShow(course, note, options))
                }

            case .courseReadyToShow(let course, let note, let options):
                state.path.removeLast()
                var resultState = CourseResultFeature.State(
                    course: course,
                    user: state.user,
                    partner: state.partner,
                    generationOptions: options
                )
                resultState.placeCountNote = note
                state.path.append(.courseResult(resultState))
                return .none

            case .redateCourseReady(let course):
                state.path.removeAll()
                state.path.append(.courseResult(CourseResultFeature.State(course: course, user: state.user, partner: state.partner)))
                return .none

            case .path(.popFrom(id: let id)):
                if case .courseResult(let courseState) = state.path[id: id], courseState.isSaved {
                    let course = courseState.course
                    if course.status == .inProgress {
                        state.inProgressCourse = course
                    } else if state.inProgressCourse?.id == course.id {
                        state.inProgressCourse = nil
                    }
                    if let idx = state.recentCourses.firstIndex(where: { $0.id == course.id }) {
                        state.recentCourses[idx] = course
                    } else {
                        state.recentCourses.insert(course, at: 0)
                    }
                }
                return .none

            case .path(.element(_, action: .courseResult(.delegate(.courseUpdated(let course))))):
                state.path.removeAll()
                if course.status == .inProgress {
                    state.inProgressCourse = course
                } else if state.inProgressCourse?.id == course.id {
                    state.inProgressCourse = nil
                }
                if let idx = state.recentCourses.firstIndex(where: { $0.id == course.id }) {
                    state.recentCourses[idx] = course
                } else {
                    state.recentCourses.insert(course, at: 0)
                }
                return .none

            case .path(.element(_, action: .courseResult(.delegate(.redate(let original))))):
                let userId = state.user.id
                let existingPartnerId = state.partner?.userId
                return .run { send in
                    let partnerId: UUID?
                    if let existing = existingPartnerId {
                        partnerId = existing
                    } else if let conn = try? await partnerConnectionRepository.fetchConnection(userId: userId) {
                        partnerId = conn.partnerId(myUserId: userId)
                    } else {
                        partnerId = nil
                    }
                    let newCourse = Course(
                        userId: userId,
                        partnerId: partnerId,
                        title: original.title,
                        date: Date(),
                        mode: original.mode,
                        places: original.places,
                        candidates: original.candidates,
                        outfitSuggestion: original.outfitSuggestion,
                        courseReason: original.courseReason
                    )
                    await send(.redateCourseReady(newCourse))
                }

            case .path(.element(_, action: .courseResult(.delegate(.dismiss)))),
                 .path(.element(_, action: .courseResult(.delegate(.deleted)))):
                state.path.removeAll()
                return .run { [userId = state.user.id] send in
                    await send(.loadCoursesResponse(
                        Result { try await fetchRecentCoursesUseCase.execute(userId: userId) }
                    ))
                }

            case .path(.element(_, action: .settings(.delegate(.openProfile)))):
                state.path.append(.profile(ProfileFeature.State(user: state.user)))
                return .none

            case .path(.element(_, action: .profile(.delegate(.saved(let user))))):
                state.user = user
                state.path.removeLast()
                return .none

            case .path(.element(_, action: .courseGenerate(.delegate(.userUpdated(let user))))):
                state.user = user
                return .none

            case .path(.element(_, action: .settings(.delegate(.openAnniversary)))):
                state.path.append(.anniversary(AnniversaryFeature.State()))
                return .none

            case .path(.element(_, action: .settings(.delegate(.openPartner(let existing, let isConnected))))):
                let mode: PartnerFeature.Mode = existing != nil ? .edit : .create
                state.path.append(.partner(PartnerFeature.State(mode: mode, existing: existing, isConnected: isConnected)))
                return .none

            case .path(.element(_, action: .settings(.delegate(.openWishlist)))):
                state.path.append(.wishlist(WishlistManageFeature.State()))
                return .none

            case .path(.element(_, action: .settings(.delegate(.openChecklist)))):
                state.path.append(.defaultChecklist)
                return .none

            case .path(.element(_, action: .settings(.delegate(.openPartnerConnect)))):
                state.path.append(.partnerConnection(PartnerConnectionFeature.State()))
                return .none

            case .path(.element(_, action: .settings(.delegate(.openTasteMap)))):
                state.showTasteMap = true
                return .none

            case .path(.element(_, action: .settings(.delegate(.loggedOut)))):
                return .send(.delegate(.loggedOut))

            case .path(.element(_, action: .partner(.delegate(.partnerSaved)))):
                state.path.removeLast()
                let userId = state.user.id
                return .run { send in
                    await send(.loadPartnerResponse(Result {
                        try await fetchEffectivePartnerUseCase.execute(userId: userId)
                    }))
                }

            case .path:
                return .none

            case .delegate:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
        .ifLet(\.$alert, action: \.alert)
    }
}

extension HomeFeature.Path.State: Equatable {}
extension HomeFeature: @unchecked Sendable {}
extension HomeFeature.Path: @unchecked Sendable {}
extension CourseGenerateFeature: @unchecked Sendable {}
extension CourseResultFeature: @unchecked Sendable {}
extension SettingsFeature: @unchecked Sendable {}
extension PartnerFeature: @unchecked Sendable {}
extension AnniversaryFeature: @unchecked Sendable {}
extension ProfileFeature: @unchecked Sendable {}
extension WishlistManageFeature: @unchecked Sendable {}
