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
        case appleLoginTapped
        case loginResponse(Result<User, Error>)
        case alert(PresentationAction<Alert>)
        case delegate(Delegate)

        public enum Alert: Equatable { case dismiss }
        public enum Delegate: Equatable { case loginSucceeded(User) }
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .kakaoLoginTapped:
                state.isLoading = true
                return .none // TODO: 카카오 OAuth 연동
            case .appleLoginTapped:
                state.isLoading = true
                return .none // TODO: 애플 로그인 연동
            case .loginResponse(.success(let user)):
                state.isLoading = false
                return .send(.delegate(.loginSucceeded(user)))
            case .loginResponse(.failure(let error)):
                state.isLoading = false
                state.alert = AlertState { TextState(error.localizedDescription) }
                return .none
            case .alert(.dismiss), .alert(.presented(.dismiss)):
                state.alert = nil
                return .none
            case .delegate:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}
