import ComposableArchitecture
import Domain

@Reducer
public struct OnboardingFeature {
    @ObservableState
    public struct State: Equatable {
        public var preferredCategories: [String] = []
        public var dislikedCategories: [String] = []
        public var preferredThemes: [String] = []
        public var isLoading = false

        public init() {}
    }

    public enum Action {
        case preferredCategoryToggled(String)
        case dislikedCategoryToggled(String)
        case themeToggled(String)
        case saveTapped
        case saveResponse(Result<User, Error>)
        case delegate(Delegate)

        public enum Delegate: Equatable { case onboardingCompleted(User) }
    }

    @Dependency(\.userRepository) var userRepository

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .preferredCategoryToggled(let category):
                if state.preferredCategories.contains(category) {
                    state.preferredCategories.removeAll { $0 == category }
                } else {
                    state.preferredCategories.append(category)
                }
                return .none
            case .dislikedCategoryToggled(let category):
                if state.dislikedCategories.contains(category) {
                    state.dislikedCategories.removeAll { $0 == category }
                } else {
                    state.dislikedCategories.append(category)
                }
                return .none
            case .themeToggled(let theme):
                if state.preferredThemes.contains(theme) {
                    state.preferredThemes.removeAll { $0 == theme }
                } else {
                    state.preferredThemes.append(theme)
                }
                return .none
            case .saveTapped:
                state.isLoading = true
                return .run { send in
                    await send(.saveResponse(
                        Result { try await userRepository.fetchCurrentUser() }
                    ))
                }
            case .saveResponse(.success(let user)):
                state.isLoading = false
                return .send(.delegate(.onboardingCompleted(user)))
            case .saveResponse(.failure):
                state.isLoading = false
                return .none
            case .delegate:
                return .none
            }
        }
    }
}
