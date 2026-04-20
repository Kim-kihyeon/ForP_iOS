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
        case categoryTapped(String)
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

            case .categoryTapped(let category):
                let isPreferred = state.preferredCategories.contains(category)
                let isDisliked = state.dislikedCategories.contains(category)
                if !isPreferred && !isDisliked {
                    state.preferredCategories.append(category)
                } else if isPreferred {
                    state.preferredCategories.removeAll { $0 == category }
                    state.dislikedCategories.append(category)
                } else {
                    state.dislikedCategories.removeAll { $0 == category }
                }
                return .none

            case .themeToggled(let item):
                state.preferredThemes.toggle(item)
                return .none

            case .saveTapped:
                guard !state.location.trimmingCharacters(in: .whitespaces).isEmpty else {
                    state.alert = AlertState { TextState("지역을 입력해주세요") } actions: { ButtonState(role: .cancel) { TextState("확인") } } message: { TextState("주로 데이트하는 동네를 입력해주세요") }
                    return .none
                }
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
