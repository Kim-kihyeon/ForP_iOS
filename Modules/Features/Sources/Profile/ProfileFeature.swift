import ComposableArchitecture
import Domain

@Reducer
public struct ProfileFeature {
    @ObservableState
    public struct State: Equatable {
        var originalUser: User
        public var nickname: String
        public var location: String
        public var preferredCategories: [String]
        public var dislikedCategories: [String]
        public var isSaving = false
        public var showSaved = false

        public var hasChanges: Bool {
            nickname != originalUser.nickname ||
            location != originalUser.location ||
            preferredCategories != originalUser.preferredCategories ||
            dislikedCategories != originalUser.dislikedCategories
        }
        @Presents public var alert: AlertState<Action.Alert>?

        public init(user: User) {
            self.originalUser = user
            self.nickname = user.nickname
            self.location = user.location
            self.preferredCategories = user.preferredCategories
            self.dislikedCategories = user.dislikedCategories
        }
    }

    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case saveTapped
        case saveResponse(Result<Void, Error>)
        case alert(PresentationAction<Alert>)
        case delegate(Delegate)

        public enum Alert: Equatable { case retrySave }
        public enum Delegate: Equatable {
            case saved(User)
        }
    }

    @Dependency(\.userRepository) var userRepository

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .saveTapped:
                guard !state.nickname.isEmpty else { return .none }
                var user = state.originalUser
                user.nickname = state.nickname
                user.location = state.location
                user.preferredCategories = state.preferredCategories
                user.dislikedCategories = state.dislikedCategories
                state.isSaving = true
                state.originalUser = user
                return .run { [user] send in
                    await send(.saveResponse(
                        Result { try await userRepository.updateUser(user) }
                    ))
                }

            case .saveResponse(.success):
                state.isSaving = false
                state.showSaved = true
                let user = state.originalUser
                return .run { send in
                    try? await Task.sleep(for: .milliseconds(700))
                    await send(.delegate(.saved(user)))
                }

            case .saveResponse(.failure(let error)):
                state.isSaving = false
                state.alert = AlertState { TextState("저장 실패") } actions: {
                    ButtonState(action: .retrySave) { TextState("다시 시도") }
                    ButtonState(role: .cancel) { TextState("취소") }
                } message: { TextState(error.localizedDescription) }
                return .none

            case .alert(.presented(.retrySave)):
                return .send(.saveTapped)

            case .alert:
                return .none

            case .delegate:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}
