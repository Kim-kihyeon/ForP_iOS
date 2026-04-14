import ComposableArchitecture
import Domain

@Reducer
public struct OnboardingFeature {
    @ObservableState
    public struct State: Equatable {
        public var user: User
        public var location = ""
        public var preferredCategories: [String] = []
        public var dislikedCategories: [String] = []
        public var preferredThemes: [String] = []
        public var isLoading = false
        @Presents public var alert: AlertState<Action.Alert>?

        public init(user: User) {
            self.user = user
        }
    }

    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case preferredCategoryToggled(String)
        case dislikedCategoryToggled(String)
        case themeToggled(String)
        case saveTapped
        case saveResponse(Result<Void, Error>)
        case alert(PresentationAction<Alert>)
        case delegate(Delegate)

        public enum Alert: Equatable {}

        public enum Delegate: Equatable { case onboardingCompleted(User) }
    }

    @Dependency(\.userRepository) var userRepository

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .preferredCategoryToggled(let item):
                state.preferredCategories.toggle(item)
                return .none

            case .dislikedCategoryToggled(let item):
                state.dislikedCategories.toggle(item)
                return .none

            case .themeToggled(let item):
                state.preferredThemes.toggle(item)
                return .none

            case .saveTapped:
                state.isLoading = true
                var user = state.user
                user.preferredCategories = state.preferredCategories
                user.dislikedCategories = state.dislikedCategories
                user.preferredThemes = state.preferredThemes
                user.location = state.location
                return .run { [user] send in
                    await send(.saveResponse(
                        Result { try await userRepository.updateUser(user) }
                    ))
                }

            case .saveResponse(.success):
                state.isLoading = false
                var user = state.user
                user.preferredCategories = state.preferredCategories
                user.dislikedCategories = state.dislikedCategories
                user.preferredThemes = state.preferredThemes
                user.location = state.location
                return .send(.delegate(.onboardingCompleted(user)))

            case .saveResponse(.failure(let error)):
                state.isLoading = false
                state.alert = AlertState { TextState("오류") } actions: { ButtonState(role: .cancel) { TextState("확인") } } message: { TextState(error.localizedDescription) }
                return .none

            case .alert:
                return .none

            case .delegate:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

private extension Array where Element == String {
    mutating func toggle(_ item: String) {
        if contains(item) { removeAll { $0 == item } }
        else { append(item) }
    }
}
