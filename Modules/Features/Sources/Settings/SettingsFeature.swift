import ComposableArchitecture
import Domain

@Reducer
public struct SettingsFeature {
    @ObservableState
    public struct State: Equatable {
        public var user: User?
        public var hasPartner = false
        public var isLoading = false
        @Presents public var alert: AlertState<Action.Alert>?

        public init() {}
    }

    public enum Action {
        case onAppear
        case resetPartnerTapped
        case resetPartnerResponse(Result<Void, Error>)
        case logoutTapped
        case alert(PresentationAction<Alert>)
        case delegate(Delegate)

        public enum Alert: Equatable {
            case confirmResetPartner
        }

        public enum Delegate: Equatable {
            case loggedOut
        }
    }

    @Dependency(\.partnerRepository) var partnerRepository
    @Dependency(\.currentUserId) var currentUserId

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .none
            case .resetPartnerTapped:
                state.alert = AlertState {
                    TextState("파트너 초기화")
                } actions: {
                    ButtonState(role: .destructive, action: .confirmResetPartner) {
                        TextState("초기화")
                    }
                    ButtonState(role: .cancel) {
                        TextState("취소")
                    }
                } message: {
                    TextState("파트너 정보가 삭제됩니다.")
                }
                return .none
            case .alert(.presented(.confirmResetPartner)):
                state.isLoading = true
                return .run { send in
                    let userId = currentUserId()
                    await send(.resetPartnerResponse(
                        Result { try await partnerRepository.deletePartner(id: userId) }
                    ))
                }
            case .alert:
                state.alert = nil
                return .none
            case .resetPartnerResponse(.success):
                state.isLoading = false
                state.hasPartner = false
                return .none
            case .resetPartnerResponse(.failure):
                state.isLoading = false
                return .none
            case .logoutTapped:
                return .send(.delegate(.loggedOut))
            case .delegate:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}
