import ComposableArchitecture
import Domain

@Reducer
public struct HomeFeature {
    @ObservableState
    public struct State: Equatable {
        public var recentCourses: [Course] = []
        public var isLoading = false

        public init() {}
    }

    public enum Action {
        case onAppear
        case loadCoursesResponse(Result<[Course], Error>)
        case generateCourseTapped
        case courseSelected(Course)
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case navigateToCourseGenerate
            case navigateToCourseResult(Course)
        }
    }

    @Dependency(\.fetchRecentCoursesUseCase) var fetchRecentCoursesUseCase
    @Dependency(\.currentUserId) var currentUserId

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                return .run { send in
                    let userId = currentUserId()
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
                return .send(.delegate(.navigateToCourseGenerate))
            case .courseSelected(let course):
                return .send(.delegate(.navigateToCourseResult(course)))
            case .delegate:
                return .none
            }
        }
    }
}
