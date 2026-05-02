import ComposableArchitecture
import Domain
import Foundation

@Reducer
public struct AppFeature {
    @ObservableState
    public struct State: Equatable {
        public var route: Route = .splash
        public var login = LoginFeature.State()
        public var onboarding = OnboardingFeature.State(user: .placeholder)
        public var home = HomeFeature.State(user: .placeholder)
        public var pendingFCMToken: String? = nil
        public var authenticatedUserId: UUID? = nil

        public enum Route: Equatable {
            case splash
            case login
            case onboarding
            case main
        }

        public init() {}
    }

    public enum Action {
        case onAppear
        case sessionChecked(Result<User?, Error>)
        case fcmTokenReceived(String)
        case login(LoginFeature.Action)
        case onboarding(OnboardingFeature.Action)
        case home(HomeFeature.Action)
    }

    @Dependency(\.authRepository) var authRepository
    @Dependency(\.userRepository) var userRepository

    public init() {}

    public var body: some ReducerOf<Self> {
        Scope(state: \.login, action: \.login) { LoginFeature() }
        Scope(state: \.onboarding, action: \.onboarding) { OnboardingFeature() }
        Scope(state: \.home, action: \.home) { HomeFeature() }

        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    await send(.sessionChecked(Result {
                        guard await authRepository.hasValidSession() else { return nil }
                        return try await userRepository.fetchCurrentUser()
                    }))
                }

            case .sessionChecked(.success(let user)):
                if let user {
                    state.authenticatedUserId = user.id
                    if user.preferredCategories.isEmpty {
                        state.onboarding = OnboardingFeature.State(user: user)
                        state.route = .onboarding
                    } else {
                        state.home = HomeFeature.State(user: user)
                        state.route = .main
                    }
                    if let token = state.pendingFCMToken {
                        state.pendingFCMToken = nil
                        return .run { _ in
                            try? await userRepository.saveFCMToken(userId: user.id, token: token)
                        }
                    }
                } else {
                    state.route = .login
                }
                return .none

            case .fcmTokenReceived(let token):
                if let userId = state.authenticatedUserId {
                    return .run { _ in
                        try? await userRepository.saveFCMToken(userId: userId, token: token)
                    }
                } else {
                    state.pendingFCMToken = token
                    return .none
                }

            case .sessionChecked(.failure):
                if state.route == .splash {
                    state.route = .login
                }
                return .none

            case .login(.delegate(.loginSucceeded(let user))):
                state.authenticatedUserId = user.id
                if user.preferredCategories.isEmpty {
                    state.onboarding = OnboardingFeature.State(user: user)
                    state.route = .onboarding
                } else {
                    state.home = HomeFeature.State(user: user)
                    state.route = .main
                }
                if let token = state.pendingFCMToken {
                    state.pendingFCMToken = nil
                    return .run { _ in
                        try? await userRepository.saveFCMToken(userId: user.id, token: token)
                    }
                }
                return .none

            case .onboarding(.delegate(.onboardingCompleted(let user))):
                state.authenticatedUserId = user.id
                state.home = HomeFeature.State(user: user)
                state.route = .main
                if let token = state.pendingFCMToken {
                    state.pendingFCMToken = nil
                    return .run { _ in
                        try? await userRepository.saveFCMToken(userId: user.id, token: token)
                    }
                }
                return .none

            case .home(.delegate(.loggedOut)):
                state.route = .login
                state.login = LoginFeature.State()
                state.authenticatedUserId = nil
                return .none

            case .login, .onboarding, .home:
                return .none
            }
        }
    }
}
