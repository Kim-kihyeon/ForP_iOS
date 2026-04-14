import ComposableArchitecture
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
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Scope(state: \.login, action: \.login) { LoginFeature() }
        Scope(state: \.home, action: \.home) { HomeFeature() }

        Reduce { state, action in
            switch action {
            case .login(.delegate(.loginSucceeded(let user))):
                state.route = .main
                return .none
            case .login, .home:
                return .none
            }
        }
    }
}
