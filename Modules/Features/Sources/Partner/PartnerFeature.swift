import ComposableArchitecture
import Domain

@Reducer
public struct PartnerFeature {
    public enum Mode: Equatable { case create, edit }

    @ObservableState
    public struct State: Equatable {
        public var nickname = ""
        public var preferredCategories: [String] = []
        public var dislikedCategories: [String] = []
        public var preferredThemes: [String] = []
        public var notes = ""
        public var isLoading = false
        public var mode: Mode = .create
        @Presents public var alert: AlertState<Action.Alert>?

        public init(mode: Mode = .create, existing: Partner? = nil) {
            self.mode = mode
            if let p = existing {
                self.nickname = p.nickname
                self.preferredCategories = p.preferredCategories
                self.dislikedCategories = p.dislikedCategories
                self.preferredThemes = p.preferredThemes
                self.notes = p.notes
            }
        }
    }

    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case saveTapped
        case saveResponse(Result<Partner, Error>)
        case alert(PresentationAction<Alert>)
        case delegate(Delegate)

        public enum Alert: Equatable {}
        public enum Delegate: Equatable { case partnerSaved(Partner) }
    }

    @Dependency(\.partnerRepository) var partnerRepository
    @Dependency(\.currentUserId) var currentUserId

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
            case .saveTapped:
                state.isLoading = true
                let partner = Partner(
                    userId: currentUserId(),
                    nickname: state.nickname,
                    preferredCategories: state.preferredCategories,
                    dislikedCategories: state.dislikedCategories,
                    preferredThemes: state.preferredThemes,
                    notes: state.notes
                )
                return .run { send in
                    await send(.saveResponse(Result {
                        try await partnerRepository.savePartner(partner)
                        return partner
                    }))
                }
            case .saveResponse(.success(let partner)):
                state.isLoading = false
                return .send(.delegate(.partnerSaved(partner)))
            case .saveResponse(.failure(let error)):
                state.isLoading = false
                state.alert = AlertState { TextState("오류") } actions: { ButtonState(role: .cancel) { TextState("확인") } } message: { TextState(error.localizedDescription) }
                return .none
            case .alert:
                return .none
            case .delegate:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}
