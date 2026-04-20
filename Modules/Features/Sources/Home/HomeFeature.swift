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
    }

    @ObservableState
    public struct State: Equatable {
        public var user: User
        public var path = StackState<Path.State>()
        public var recentCourses: [Course] = []
        public var likedCourses: [Course] { recentCourses.filter { $0.isLiked } }
        public var upcomingAnniversary: Anniversary? = nil
        public var weather: WeatherInfo? = nil
        public var isLoading = false
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
        case loadAnniversariesResponse(Result<[Anniversary], Error>)
        case loadWeatherResponse(Result<WeatherInfo, Error>)
        case generateCourseTapped
        case courseSelected(Course)
        case settingsTapped
        case alert(PresentationAction<Alert>)
        case delegate(Delegate)

        public enum Alert: Equatable {}
        public enum Delegate: Equatable {
            case loggedOut
        }
    }

    @Dependency(\.fetchRecentCoursesUseCase) var fetchRecentCoursesUseCase
    @Dependency(\.currentPartner) var currentPartner
    @Dependency(\.anniversaryRepository) var anniversaryRepository
    @Dependency(\.notificationService) var notificationService: any NotificationServiceProtocol
    @Dependency(\.weatherService) var weatherService: any WeatherServiceProtocol

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = state.recentCourses.isEmpty
                return .run { [userId = state.user.id] send in
                    await send(.loadCoursesResponse(
                        Result { try await fetchRecentCoursesUseCase.execute(userId: userId) }
                    ))
                    await send(.loadAnniversariesResponse(
                        Result { try await anniversaryRepository.fetchAnniversaries(userId: userId) }
                    ))
                    await send(.loadWeatherResponse(
                        Result { try await weatherService.fetchWeather(latitude: 37.5665, longitude: 126.9780, date: Date()) }
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

            case .loadAnniversariesResponse(.success(let anniversaries)):
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

            case .alert:
                return .none

            case .generateCourseTapped:
                state.path.append(.courseGenerate(CourseGenerateFeature.State(user: state.user)))
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
                    outfitSuggestion: plan.outfitSuggestion
                )
                state.path.removeLast()
                state.path.append(.courseResult(CourseResultFeature.State(course: course, candidates: plan.candidates, courseReason: plan.courseReason)))
                return .none

            case .path(.popFrom(id: let id)):
                if case .courseResult(let courseState) = state.path[id: id], courseState.isSaved {
                    let course = courseState.course
                    if let idx = state.recentCourses.firstIndex(where: { $0.id == course.id }) {
                        state.recentCourses[idx] = course
                    }
                }
                return .none

            case .path(.element(_, action: .courseResult(.delegate(.courseUpdated(let course))))):
                state.path.removeAll()
                if let idx = state.recentCourses.firstIndex(where: { $0.id == course.id }) {
                    state.recentCourses[idx] = course
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

            case .path(.element(_, action: .settings(.delegate(.openAnniversary)))):
                state.path.append(.anniversary(AnniversaryFeature.State()))
                return .none

            case .path(.element(_, action: .settings(.delegate(.openPartner(let existing))))):
                let mode: PartnerFeature.Mode = existing != nil ? .edit : .create
                state.path.append(.partner(PartnerFeature.State(mode: mode, existing: existing)))
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
