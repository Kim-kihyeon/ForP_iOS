import ComposableArchitecture
import Domain

@Reducer
public struct CourseResultFeature {
    @ObservableState
    public struct State: Equatable {
        public var course: Course
        public var isSaving = false
        public var isSaved = false

        public init(course: Course) {
            self.course = course
        }
    }

    public enum Action {
        case saveTapped
        case saveResponse(Result<Void, Error>)
        case dismissTapped
        case delegate(Delegate)

        public enum Delegate: Equatable { case dismiss }
    }

    @Dependency(\.saveCourseUseCase) var saveCourseUseCase

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .saveTapped:
                state.isSaving = true
                let course = state.course
                return .run { send in
                    await send(.saveResponse(
                        Result { try await saveCourseUseCase.execute(course) }
                    ))
                }
            case .saveResponse(.success):
                state.isSaving = false
                state.isSaved = true
                return .none
            case .saveResponse(.failure):
                state.isSaving = false
                return .none
            case .dismissTapped:
                return .send(.delegate(.dismiss))
            case .delegate:
                return .none
            }
        }
    }
}
