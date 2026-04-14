import ComposableArchitecture
import Domain

@Reducer
public struct HomeFeature {
    @Reducer
    public enum Path {
        case courseGenerate(CourseGenerateFeature)
        case courseResult(CourseResultFeature)
        case settings(SettingsFeature)
        case partner(PartnerFeature)
    }

    @ObservableState
    public struct State: Equatable {
        public var user: User
        public var path = StackState<Path.State>()
        public var recentCourses: [Course] = []
        public var isLoading = false

        public init(user: User) {
            self.user = user
        }
    }

    public enum Action {
        case path(StackActionOf<Path>)
        case onAppear
        case loadCoursesResponse(Result<[Course], Error>)
        case generateCourseTapped
        case courseSelected(Course)
        case settingsTapped
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case loggedOut
        }
    }

    @Dependency(\.fetchRecentCoursesUseCase) var fetchRecentCoursesUseCase
    @Dependency(\.currentPartner) var currentPartner

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                return .run { [userId = state.user.id] send in
                    await send(.loadCoursesResponse(
                        Result { try await fetchRecentCoursesUseCase.execute(userId: userId) }
                    ))
                }

            case .loadCoursesResponse(.success(let courses)):
                state.isLoading = false
                state.recentCourses = courses
                return .none

            case .loadCoursesResponse(.failure):
                state.isLoading = false
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

            case .path(.element(_, action: .courseGenerate(.delegate(.courseGenerated(let places, let options))))):
                let course = Course(
                    userId: state.user.id,
                    title: "\(options.location) 데이트",
                    mode: options.mode,
                    places: places
                )
                state.path.append(.courseResult(CourseResultFeature.State(course: course)))
                return .none

            case .path(.element(_, action: .courseResult(.delegate(.dismiss)))),
                 .path(.element(_, action: .courseResult(.delegate(.deleted)))):
                state.path.removeAll()
                return .run { [userId = state.user.id] send in
                    await send(.loadCoursesResponse(
                        Result { try await fetchRecentCoursesUseCase.execute(userId: userId) }
                    ))
                }

            case .path(.element(_, action: .settings(.delegate(.openPartner)))):
                let existing = currentPartner()
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
    }
}

extension HomeFeature.Path.State: Equatable {}
