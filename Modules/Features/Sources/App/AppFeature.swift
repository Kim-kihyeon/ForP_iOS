import ComposableArchitecture
import Domain

@Reducer
public struct AppFeature {
    @ObservableState
    public struct State: Equatable {
        public var route: Route = .login
        public var login = LoginFeature.State()
        public var onboarding = OnboardingFeature.State()
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
                // 취향 미설정 신규 유저 → 온보딩, 기존 유저 → 메인
                if user.preferredCategories.isEmpty {
                    state.route = .onboarding
                } else {
                    state.route = .main
                }
                return .none

            case .onboarding(.delegate(.onboardingCompleted)):
                state.route = .main
                return .none

            case .login, .onboarding, .home:
                return .none
            }
        }
    }
}
