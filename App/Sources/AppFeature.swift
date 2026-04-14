import ComposableArchitecture
import Features
import Domain

@Reducer
public struct AppFeature {
    @ObservableState
    public struct State: Equatable {
        public var route: Route = .login
        public var login = LoginFeature.State()
        public var home = HomeFeature.State()

        public enum Route: Equatable {
            case login
            case onboarding
            case main
        }

        public init() {}
    }

    public enum Action {
        case login(LoginFeature.Action)
        case home(HomeFeature.Action)
        case authStateChanged(isLoggedIn: Bool)
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Scope(state: \.login, action: \.login) { LoginFeature() }
        Scope(state: \.home, action: \.home) { HomeFeature() }

        Reduce { state, action in
            switch action {
            case .login(.delegate(.loginSucceeded)):
                state.route = .main
                return .none
            case .authStateChanged(let isLoggedIn):
                state.route = isLoggedIn ? .main : .login
                return .none
            case .login, .home:
                return .none
            }
        }
    }
}
