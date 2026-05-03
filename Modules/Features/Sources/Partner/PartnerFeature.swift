import ComposableArchitecture
import Domain
import Foundation

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
        public var foodBlacklist: [String] = []
        public var isLoading = false
        public var showSaved = false
        public var mode: Mode = .create
        public var isConnected: Bool = false
        var existingPartnerId: UUID? = nil
        @Presents public var alert: AlertState<Action.Alert>?

        var originalNickname = ""
        var originalPreferredCategories: [String] = []
        var originalDislikedCategories: [String] = []
        var originalNotes = ""
        var originalFoodBlacklist: [String] = []

        public var hasChanges: Bool {
            if isConnected { return notes != originalNotes }
            return nickname != originalNickname ||
                preferredCategories != originalPreferredCategories ||
                dislikedCategories != originalDislikedCategories ||
                notes != originalNotes ||
                foodBlacklist != originalFoodBlacklist
        }

        public init(mode: Mode = .create, existing: Partner? = nil, isConnected: Bool = false) {
            self.mode = mode
            self.isConnected = isConnected
            if let p = existing {
                self.existingPartnerId = p.id
                self.nickname = p.nickname
                self.preferredCategories = p.preferredCategories
                self.dislikedCategories = p.dislikedCategories
                self.preferredThemes = p.preferredThemes
                self.notes = p.notes
                self.foodBlacklist = p.foodBlacklist
                self.originalNickname = p.nickname
                self.originalPreferredCategories = p.preferredCategories
                self.originalDislikedCategories = p.dislikedCategories
                self.originalNotes = p.notes
                self.originalFoodBlacklist = p.foodBlacklist
            }
        }
    }

    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case categoryTapped(String)
        case saveTapped
        case saveResponse(Result<Partner, Error>)
        case alert(PresentationAction<Alert>)
        case delegate(Delegate)

        public enum Alert: Equatable { case retrySave }
        public enum Delegate: Equatable { case partnerSaved(Partner) }
    }

    @Dependency(\.partnerRepository) var partnerRepository
    @Dependency(\.currentUserId) var currentUserId

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .categoryTapped(let category):
                let isPreferred = state.preferredCategories.contains(category)
                let isDisliked = state.dislikedCategories.contains(category)
                if !isPreferred && !isDisliked {
                    state.preferredCategories.append(category)
                } else if isPreferred {
                    state.preferredCategories.removeAll { $0 == category }
                    state.dislikedCategories.append(category)
                } else {
                    state.dislikedCategories.removeAll { $0 == category }
                }
                return .none
            case .binding:
                return .none
            case .saveTapped:
                guard let userId = currentUserId() else {
                    state.alert = AlertState { TextState("저장 실패") } actions: {
                        ButtonState(role: .cancel) { TextState("확인") }
                    } message: {
                        TextState("로그인 상태를 확인한 뒤 다시 시도해주세요.")
                    }
                    return .none
                }
                state.isLoading = true
                let partner = Partner(
                    id: state.existingPartnerId ?? UUID(),
                    userId: userId,
                    nickname: state.nickname,
                    preferredCategories: state.preferredCategories,
                    dislikedCategories: state.dislikedCategories,
                    preferredThemes: state.preferredThemes,
                    notes: state.notes,
                    foodBlacklist: state.foodBlacklist
                )
                return .run { send in
                    await send(.saveResponse(Result {
                        try await partnerRepository.savePartner(partner)
                        return partner
                    }))
                }
            case .saveResponse(.success(let partner)):
                state.isLoading = false
                state.showSaved = true
                return .run { send in
                    try? await Task.sleep(for: .milliseconds(700))
                    await send(.delegate(.partnerSaved(partner)))
                }
            case .saveResponse(.failure(let error)):
                state.isLoading = false
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
