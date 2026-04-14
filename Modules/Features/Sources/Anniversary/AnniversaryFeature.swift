import Foundation
import ComposableArchitecture
import Domain

@Reducer
public struct AnniversaryFeature {
    @ObservableState
    public struct State: Equatable {
        public var anniversaries: [Anniversary] = []
        public var isLoading = false
        public var isEditing = false
        public var editingName = ""
        public var editingDate = Date()
        public var editingId: UUID? = nil
        @Presents public var alert: AlertState<Action.Alert>?

        public init() {}
    }

    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case onAppear
        case loadResponse(Result<[Anniversary], Error>)
        case addTapped
        case editTapped(Anniversary)
        case saveTapped
        case saveResponse(Result<Void, Error>)
        case deleteTapped(Anniversary)
        case deleteResponse(Result<Void, Error>)
        case cancelTapped
        case alert(PresentationAction<Alert>)

        public enum Alert: Equatable {}
    }

    @Dependency(\.anniversaryRepository) var anniversaryRepository
    @Dependency(\.currentUserId) var currentUserId
    @Dependency(\.notificationService) var notificationService: any NotificationServiceProtocol

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .onAppear:
                state.isLoading = true
                let userId = currentUserId()
                return .run { send in
                    await send(.loadResponse(Result {
                        try await anniversaryRepository.fetchAnniversaries(userId: userId)
                    }))
                }

            case .loadResponse(.success(let anniversaries)):
                state.isLoading = false
                state.anniversaries = anniversaries
                return .run { [anniversaries] _ in
                    await notificationService.scheduleAnniversaryNotifications(for: anniversaries)
                }

            case .loadResponse(.failure(let error)):
                state.isLoading = false
                state.alert = AlertState { TextState("오류") } actions: { ButtonState(role: .cancel) { TextState("확인") } } message: { TextState(error.localizedDescription) }
                return .none

            case .addTapped:
                state.editingId = nil
                state.editingName = ""
                state.editingDate = Date()
                state.isEditing = true
                return .none

            case .editTapped(let anniversary):
                state.editingId = anniversary.id
                state.editingName = anniversary.name
                state.editingDate = anniversary.date
                state.isEditing = true
                return .none

            case .cancelTapped:
                state.isEditing = false
                return .none

            case .saveTapped:
                guard !state.editingName.isEmpty else { return .none }
                state.isLoading = true
                state.isEditing = false
                let anniversary = Anniversary(
                    id: state.editingId ?? UUID(),
                    userId: currentUserId(),
                    name: state.editingName,
                    date: state.editingDate
                )
                return .run { send in
                    await send(.saveResponse(Result {
                        try await anniversaryRepository.saveAnniversary(anniversary)
                    }))
                }

            case .saveResponse(.success):
                let userId = currentUserId()
                return .run { send in
                    await send(.loadResponse(Result {
                        try await anniversaryRepository.fetchAnniversaries(userId: userId)
                    }))
                }

            case .saveResponse(.failure(let error)):
                state.isLoading = false
                state.alert = AlertState { TextState("오류") } actions: { ButtonState(role: .cancel) { TextState("확인") } } message: { TextState(error.localizedDescription) }
                return .none

            case .deleteTapped(let anniversary):
                state.isLoading = true
                return .run { send in
                    await send(.deleteResponse(Result {
                        try await anniversaryRepository.deleteAnniversary(id: anniversary.id)
                    }))
                }

            case .deleteResponse(.success):
                let userId = currentUserId()
                return .run { send in
                    await send(.loadResponse(Result {
                        try await anniversaryRepository.fetchAnniversaries(userId: userId)
                    }))
                }

            case .deleteResponse(.failure(let error)):
                state.isLoading = false
                state.alert = AlertState { TextState("오류") } actions: { ButtonState(role: .cancel) { TextState("확인") } } message: { TextState(error.localizedDescription) }
                return .none

            case .alert:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}
