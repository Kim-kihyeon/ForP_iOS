import ComposableArchitecture
import Domain
import Foundation

@Reducer
public struct PartnerConnectionFeature {
    @ObservableState
    public struct State: Equatable {
        public var myCode = ""
        public var inputCode = ""
        public var connection: PartnerConnection? = nil
        public var connectedUser: User? = nil
        public var isLoading = false
        @Presents public var alert: AlertState<Action.Alert>?

        public init() {}
    }

    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case onAppear
        case loaded(code: String, connection: PartnerConnection?, connectedUser: User?)
        case connectTapped
        case connectResponse(Result<(PartnerConnection, User), Error>)
        case disconnectTapped
        case disconnectResponse(Result<Void, Error>)
        case alert(PresentationAction<Alert>)

        public enum Alert: Equatable { case confirmDisconnect }
    }

    @Dependency(\.partnerConnectionRepository) var repo
    @Dependency(\.currentUserId) var currentUserId

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                guard let userId = currentUserId() else {
                    state.isLoading = false
                    return .none
                }
                return .run { send in
                    let code = (try? await repo.getOrCreateMyCode(userId: userId)) ?? ""
                    let pair: (PartnerConnection, User)? = try? await {
                        guard let conn = try await repo.fetchConnection(userId: userId) else { return nil }
                        let user = try await repo.fetchUser(id: conn.partnerId(myUserId: userId))
                        return (conn, user)
                    }()
                    await send(.loaded(code: code, connection: pair?.0, connectedUser: pair?.1))
                }

            case .loaded(let code, let connection, let connectedUser):
                state.myCode = code
                state.connection = connection
                state.connectedUser = connectedUser
                state.isLoading = false
                return .none

            case .connectTapped:
                let code = state.inputCode.trimmingCharacters(in: .whitespaces).uppercased()
                guard !code.isEmpty else { return .none }
                guard let userId = currentUserId() else {
                    state.alert = AlertState { TextState("연동 실패") } actions: {
                        ButtonState(role: .cancel) { TextState("확인") }
                    } message: {
                        TextState("로그인 상태를 확인한 뒤 다시 시도해주세요.")
                    }
                    return .none
                }
                state.isLoading = true
                return .run { send in
                    await send(.connectResponse(Result {
                        let conn = try await repo.connect(code: code, myUserId: userId)
                        let user = try await repo.fetchUser(id: conn.partnerId(myUserId: userId))
                        return (conn, user)
                    }))
                }

            case .connectResponse(.success(let pair)):
                state.isLoading = false
                state.connection = pair.0
                state.connectedUser = pair.1
                state.inputCode = ""
                return .none

            case .connectResponse(.failure(let error)):
                state.isLoading = false
                state.alert = AlertState { TextState("연동 실패") } actions: {
                    ButtonState(role: .cancel) { TextState("확인") }
                } message: { TextState(error.localizedDescription) }
                return .none

            case .disconnectTapped:
                state.alert = AlertState {
                    TextState("연동 해제")
                } actions: {
                    ButtonState(role: .destructive, action: .confirmDisconnect) { TextState("해제") }
                    ButtonState(role: .cancel) { TextState("취소") }
                } message: {
                    TextState("파트너 연동을 해제할까요?")
                }
                return .none

            case .alert(.presented(.confirmDisconnect)):
                guard let id = state.connection?.id else { return .none }
                state.isLoading = true
                return .run { send in
                    await send(.disconnectResponse(Result { try await repo.disconnect(connectionId: id) }))
                }

            case .disconnectResponse(.success):
                state.isLoading = false
                state.connection = nil
                state.connectedUser = nil
                return .none

            case .disconnectResponse(.failure(let error)):
                state.isLoading = false
                state.alert = AlertState { TextState("연동 해제 실패") } actions: { ButtonState(role: .cancel) { TextState("확인") } } message: { TextState(error.localizedDescription) }
                return .none

            case .binding, .alert:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

extension PartnerConnectionFeature: @unchecked Sendable {}
