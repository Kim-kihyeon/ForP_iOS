import ComposableArchitecture
import Domain

@Reducer
public struct SettingsFeature {
    @ObservableState
    public struct State: Equatable {
        public var user: User?
        public var partner: Partner? = nil
        public var hasPartner: Bool { partner != nil }
        public var isLoading = false
        @Presents public var alert: AlertState<Action.Alert>?

        public init() {}
    }

    public enum Action {
        case onAppear
        case loadPartnerResponse(Result<Partner?, Error>)
        case profileTapped
        case partnerTapped
        case anniversaryTapped
        case resetPartnerTapped
        case resetPartnerResponse(Result<Void, Error>)
        case logoutTapped
        case logoutResponse(Result<Void, Error>)
        case alert(PresentationAction<Alert>)
        case delegate(Delegate)

        public enum Alert: Equatable {
            case confirmResetPartner
            case confirmLogout
        }

        public enum Delegate: Equatable {
            case openProfile
            case openPartner(Partner?)
            case openAnniversary
            case loggedOut
        }
    }

    @Dependency(\.authRepository) var authRepository
    @Dependency(\.partnerRepository) var partnerRepository
    @Dependency(\.currentUserId) var currentUserId

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                let userId = currentUserId()
                return .run { send in
                    await send(.loadPartnerResponse(Result {
                        try await partnerRepository.fetchPartner(for: userId)
                    }))
                }

            case .loadPartnerResponse(.success(let partner)):
                state.partner = partner
                return .none

            case .loadPartnerResponse(.failure):
                return .none

            case .profileTapped:
                return .send(.delegate(.openProfile))

            case .partnerTapped:
                return .send(.delegate(.openPartner(state.partner)))

            case .anniversaryTapped:
                return .send(.delegate(.openAnniversary))

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

            case .alert(.presented(.confirmLogout)):
                state.isLoading = true
                return .run { send in
                    await send(.logoutResponse(
                        Result { try await authRepository.logout() }
                    ))
                }

            case .alert:
                return .none

            case .resetPartnerResponse(.success):
                state.isLoading = false
                state.partner = nil
                return .none

            case .resetPartnerResponse(.failure):
                state.isLoading = false
                return .none

            case .logoutTapped:
                state.alert = AlertState {
                    TextState("로그아웃")
                } actions: {
                    ButtonState(role: .destructive, action: .confirmLogout) {
                        TextState("로그아웃")
                    }
                    ButtonState(role: .cancel) {
                        TextState("취소")
                    }
                } message: {
                    TextState("정말 로그아웃할까요?")
                }
                return .none

            case .logoutResponse(.success):
                state.isLoading = false
                return .send(.delegate(.loggedOut))

            case .logoutResponse(.failure):
                state.isLoading = false
                return .none

            case .delegate:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}
