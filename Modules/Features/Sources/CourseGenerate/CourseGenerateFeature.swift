import ComposableArchitecture
import Domain

@Reducer
public struct CourseGenerateFeature {
    @ObservableState
    public struct State: Equatable {
        public var user: User
        public var location = ""
        public var selectedThemes: [String] = []
        public var placeCount = 3
        public var mode: CourseMode = .ordered
        public var isGenerating = false
        public var errorMessage: String? = nil

        public init(user: User) {
            self.user = user
        }
    }

    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case generateTapped
        case generateResponse(Result<CoursePlan, Error>)
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case courseGenerated(CoursePlan, CourseOptions)
        }
    }

    @Dependency(\.generateCourseUseCase) var generateCourseUseCase
    @Dependency(\.currentPartner) var currentPartner

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
            case .generateTapped:
                state.isGenerating = true
                let options = CourseOptions(
                    location: state.location,
                    themes: state.selectedThemes,
                    placeCount: state.placeCount,
                    mode: state.mode
                )
                return .run { [options, user = state.user] send in
                    let partner = currentPartner()
                    await send(.generateResponse(
                        Result { try await generateCourseUseCase.execute(user: user, partner: partner, options: options) }
                    ))
                }
            case .generateResponse(.success(let plan)):
                state.isGenerating = false
                let options = CourseOptions(
                    location: state.location,
                    themes: state.selectedThemes,
                    placeCount: state.placeCount,
                    mode: state.mode
                )
                return .send(.delegate(.courseGenerated(plan, options)))
            case .generateResponse(.failure(let error)):
                state.isGenerating = false
                state.errorMessage = error.localizedDescription
                return .none
            case .delegate:
                return .none
            }
        }
    }
}
