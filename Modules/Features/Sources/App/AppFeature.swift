import ComposableArchitecture
import Domain

@Reducer
public struct AppFeature {
    @ObservableState
    public struct State: Equatable {
        public var route: Route = .login
        public var login = LoginFeature.State()
        public var onboarding = OnboardingFeature.State(user: .placeholder)
        public var home = HomeFeature.State(user: .placeholder)

        public enum Route: Equatable {
            case login
            case onboarding
            case main
        }

        public init() {}
    }

    public enum Action {
        case login(LoginFeature.Action)
        case onboarding(OnboardingFeature.Action)
        case home(HomeFeature.Action)
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Scope(state: \.login, action: \.login) { LoginFeature() }
        Scope(state: \.onboarding, action: \.onboarding) { OnboardingFeature() }
        Scope(state: \.home, action: \.home) { HomeFeature() }

        Reduce { state, action in
            switch action {
            case .login(.delegate(.loginSucceeded(let user))):
                if user.preferredCategories.isEmpty {
                    state.onboarding = OnboardingFeature.State(user: user)
                    state.route = .onboarding
                } else {
                    state.home = HomeFeature.State(user: user)
                    state.route = .main
                }
                return .none

            case .onboarding(.delegate(.onboardingCompleted(let user))):
                state.home = HomeFeature.State(user: user)
                state.route = .main
                return .none

            case .home(.delegate(.loggedOut)):
                state.route = .login
                state.login = LoginFeature.State()
                return .none

            case .login, .onboarding, .home:
                return .none
            }
        }
    }
}
