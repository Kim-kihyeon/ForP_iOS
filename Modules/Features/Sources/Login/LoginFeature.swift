import ComposableArchitecture
import Domain

@Reducer
public struct LoginFeature {
    @ObservableState
    public struct State: Equatable {
        public var isLoading = false
        @Presents public var alert: AlertState<Action.Alert>?

        public init() {}
    }

    public enum Action {
        case kakaoLoginTapped
        case appleLoginCompleted(idToken: String, nonce: String)
        case loginResponse(Result<User, Error>)
        case alert(PresentationAction<Alert>)
        case delegate(Delegate)

        public enum Alert: Equatable { case dismiss }
        public enum Delegate: Equatable { case loginSucceeded(User) }
    }

    @Dependency(\.authRepository) var authRepository
    @Dependency(\.userRepository) var userRepository

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .kakaoLoginTapped:
                state.isLoading = true
                return .run { send in
                    await send(.loginResponse(
                        Result { try await authRepository.loginWithKakao() }
                    ))
                }

            case .appleLoginCompleted(let idToken, let nonce):
                state.isLoading = true
                return .run { send in
                    await send(.loginResponse(
                        Result { try await authRepository.loginWithApple(idToken: idToken, nonce: nonce) }
                    ))
                }

            case .loginResponse(.success(let user)):
                state.isLoading = false
                return .run { send in
                    let fullUser = (try? await userRepository.fetchCurrentUser()) ?? user
                    await send(.delegate(.loginSucceeded(fullUser)))
                }

            case .loginResponse(.failure(let error)):
                state.isLoading = false
                state.alert = AlertState {
                    TextState("로그인 실패")
                } actions: {
                    ButtonState(action: .dismiss) { TextState("확인") }
                } message: {
                    TextState(error.localizedDescription)
                }
                return .none

            case .alert(.presented(.dismiss)), .alert(.dismiss):
                state.alert = nil
                return .none

            case .delegate:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}
