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
        public var upcomingAnniversary: Anniversary? = nil
        public var allAnniversaries: [Anniversary] = []
        public var weather: WeatherInfo? = nil
        public var isLoading = false
        public var showMonthlyReport = false
        public var monthlyCourses: [Course] = []
        public var isLoadingMonthly = false
        public var showTasteMap = false
        public var showCalendar = false
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
        case loadPartnerResponse(Result<Partner?, Error>)
        case loadAnniversariesResponse(Result<[Anniversary], Error>)
        case loadWeatherResponse(Result<WeatherInfo, Error>)
        case generateCourseTapped
        case courseSelected(Course)
        case settingsTapped
        case monthlyReportTapped
        case monthlyReportDismissed
        case loadMonthlyCoursesResponse(Result<[Course], Error>)
        case tasteMapDismissed
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
    @Dependency(\.partnerRepository) var partnerRepository
    @Dependency(\.partnerConnectionRepository) var partnerConnectionRepository
    @Dependency(\.anniversaryRepository) var anniversaryRepository
    @Dependency(\.notificationService) var notificationService: any NotificationServiceProtocol
    @Dependency(\.weatherService) var weatherService: any WeatherServiceProtocol
    @Dependency(\.placeRepository) var placeRepository
    @Dependency(\.courseRepository) var courseRepository: any CourseRepositoryProtocol

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = state.recentCourses.isEmpty
                let userLocation = state.user.location
                return .run { [userId = state.user.id] send in
                    await send(.loadCoursesResponse(
                        Result { try await fetchRecentCoursesUseCase.execute(userId: userId) }
                    ))
                    await send(.loadPartnerResponse(Result {
                        if let conn = try await partnerConnectionRepository.fetchConnection(userId: userId) {
                            let connectedUser = try await partnerConnectionRepository.fetchUser(id: conn.partnerId(myUserId: userId))
                            return Partner(
                                userId: connectedUser.id,
                                nickname: connectedUser.nickname,
                                preferredCategories: connectedUser.preferredCategories,
                                dislikedCategories: connectedUser.dislikedCategories,
                                preferredThemes: connectedUser.preferredThemes,
                                foodBlacklist: connectedUser.foodBlacklist
                            )
                        }
                        return try await partnerRepository.fetchPartner(for: userId)
                    }))
                    await send(.loadAnniversariesResponse(
                        Result { try await anniversaryRepository.fetchAnniversaries(userId: userId) }
                    ))
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

            case .refresh:
                return .run { [userId = state.user.id] send in
                    await send(.loadCoursesResponse(
                        Result { try await fetchRecentCoursesUseCase.execute(userId: userId) }
                    ))
                    await send(.loadAnniversariesResponse(
                        Result { try await anniversaryRepository.fetchAnniversaries(userId: userId) }
                    ))
                }

            case .loadCoursesResponse(.success(let courses)):
                state.isLoading = false
                state.recentCourses = courses
                return .none

            case .loadPartnerResponse(.success(let partner)):
                state.partner = partner
                return .none

            case .loadPartnerResponse(.failure):
                return .none

            case .loadAnniversariesResponse(.success(let anniversaries)):
                state.allAnniversaries = anniversaries
                state.upcomingAnniversary = anniversaries.sorted { $0.daysUntilThisYear < $1.daysUntilThisYear }.first
                let anniversariesCopy = anniversaries
                _Concurrency.Task.detached {
                    await notificationService.scheduleAnniversaryNotifications(for: anniversariesCopy)
                }
                return .none

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

            case .tasteMapDismissed:
                state.showTasteMap = false
                return .none

            case .calendarTapped:
                state.showCalendar = true
                return .none

            case .calendarDismissed:
                state.showCalendar = false
                return .none

            case .calendarCourseSelected(let course):
                state.showCalendar = false
                state.path.append(.courseResult(CourseResultFeature.State(course: course, isSaved: true)))
                return .none

            case .alert:
                return .none

            case .generateCourseTapped:
                state.path.append(.courseGenerate(CourseGenerateFeature.State(user: state.user, partner: state.partner)))
                return .none

            case .courseSelected(let course):
                state.path.append(.courseResult(CourseResultFeature.State(course: course, isSaved: true)))
                return .none

            case .settingsTapped:
                state.path.append(.settings(SettingsFeature.State()))
                return .none

            case .path(.element(_, action: .courseGenerate(.delegate(.courseGenerated(let plan, let options))))):
                let course = Course(
                    userId: state.user.id,
                    title: "\(options.location) 데이트",
                    mode: options.mode,
                    places: plan.places,
                    candidates: plan.candidates,
                    outfitSuggestion: plan.outfitSuggestion,
                    courseReason: plan.courseReason
                )
                state.path.removeLast()
                state.path.append(.courseResult(CourseResultFeature.State(course: course)))
                return .none

            case .path(.popFrom(id: let id)):
                if case .courseResult(let courseState) = state.path[id: id], courseState.isSaved {
                    let course = courseState.course
                    if let idx = state.recentCourses.firstIndex(where: { $0.id == course.id }) {
                        state.recentCourses[idx] = course
                    } else {
                        state.recentCourses.insert(course, at: 0)
                    }
                }
                return .none

            case .path(.element(_, action: .courseResult(.delegate(.courseUpdated(let course))))):
                state.path.removeAll()
                if let idx = state.recentCourses.firstIndex(where: { $0.id == course.id }) {
                    state.recentCourses[idx] = course
                } else {
                    state.recentCourses.insert(course, at: 0)
                }
                return .none

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

            case .path(.element(_, action: .settings(.delegate(.openPartner(let existing))))):
                let mode: PartnerFeature.Mode = existing != nil ? .edit : .create
                state.path.append(.partner(PartnerFeature.State(mode: mode, existing: existing)))
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
                return .none

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
