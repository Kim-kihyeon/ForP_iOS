import ComposableArchitecture
import Domain

@Reducer
public struct CourseResultFeature {
    @ObservableState
    public struct State: Equatable {
        public var course: Course
        public var isSaving = false
        public var isSaved: Bool
        public var isDeleting = false
        @Presents public var alert: AlertState<Action.Alert>?

        public init(course: Course, isSaved: Bool = false) {
            self.course = course
            self.isSaved = isSaved
        }
    }

    public enum Action {
        case saveTapped
        case saveResponse(Result<Void, Error>)
        case deleteTapped
        case deleteResponse(Result<Void, Error>)
        case dismissTapped
        case alert(PresentationAction<Alert>)
        case delegate(Delegate)

        public enum Alert: Equatable { case confirmDelete }
        public enum Delegate: Equatable {
            case dismiss
            case deleted
        }
    }

    @Dependency(\.saveCourseUseCase) var saveCourseUseCase
    @Dependency(\.courseRepository) var courseRepository

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

            case .saveResponse(.failure(let error)):
                state.isSaving = false
                state.alert = AlertState { TextState("오류") } actions: { ButtonState(role: .cancel) { TextState("확인") } } message: { TextState(error.localizedDescription) }
                return .none

            case .deleteTapped:
                state.alert = AlertState {
                    TextState("코스 삭제")
                } actions: {
                    ButtonState(role: .destructive, action: .confirmDelete) {
                        TextState("삭제")
                    }
                    ButtonState(role: .cancel) {
                        TextState("취소")
                    }
                } message: {
                    TextState("이 코스를 삭제할까요?")
                }
                return .none

            case .alert(.presented(.confirmDelete)):
                state.isDeleting = true
                let id = state.course.id
                return .run { send in
                    await send(.deleteResponse(
                        Result { try await courseRepository.deleteCourse(id: id) }
                    ))
                }

            case .alert:
                return .none

            case .deleteResponse(.success):
                state.isDeleting = false
                return .send(.delegate(.deleted))

            case .deleteResponse(.failure(let error)):
                state.isDeleting = false
                state.alert = AlertState { TextState("오류") } actions: { ButtonState(role: .cancel) { TextState("확인") } } message: { TextState(error.localizedDescription) }
                return .none

            case .dismissTapped:
                return .send(.delegate(.dismiss))

            case .delegate:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}
