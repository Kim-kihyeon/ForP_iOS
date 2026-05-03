import ComposableArchitecture
import Domain
import UIKit

@Reducer
public struct SettingsFeature {
    @ObservableState
    public struct State: Equatable {
        public var user: User?
        public var partner: Partner? = nil
        public var hasPartner: Bool { partner != nil }
        public var isConnected: Bool = false
        public var isLoadingPartner = true
        public var isLoading = false
        public var notificationSettings: NotificationSettings = .default
        public var notificationPermissionStatus: NotificationPermissionStatus = .notDetermined
        @Presents public var alert: AlertState<Action.Alert>?

        public init() {}
    }

    public enum Action {
        case onAppear
        case loadPartnerResponse(Result<Partner?, Error>)
        case connectionChecked(Bool)
        case notificationPermissionLoaded(NotificationPermissionStatus)
        case notificationSettingsResponse(Result<NotificationSettings, Error>)
        case profileTapped
        case partnerTapped
        case anniversaryTapped
        case wishlistTapped
        case checklistTapped
        case tasteMapTapped
        case pushNotificationToggled(Bool)
        case courseReminderToggled(Bool)
        case anniversaryNotificationToggled(Bool)
        case partnerNotificationToggled(Bool)
        case partnerConnectTapped
        case resetPartnerTapped
        case resetPartnerResponse(Result<Void, Error>)
        case logoutTapped
        case logoutResponse(Result<Void, Error>)
        case deleteAccountTapped
        case deleteAccountResponse(Result<Void, Error>)
        case alert(PresentationAction<Alert>)
        case delegate(Delegate)

        public enum Alert: Equatable {
            case confirmResetPartner
            case confirmLogout
            case confirmDeleteAccount
            case openSystemNotificationSettings
        }

        public enum Delegate: Equatable {
            case openProfile
            case openPartner(Partner?, isConnected: Bool)
            case openAnniversary
            case openWishlist
            case openChecklist
            case openTasteMap
            case openPartnerConnect
            case loggedOut
        }
    }

    @Dependency(\.authRepository) var authRepository
    @Dependency(\.fetchEffectivePartnerUseCase) var fetchEffectivePartnerUseCase
    @Dependency(\.partnerRepository) var partnerRepository
    @Dependency(\.partnerConnectionRepository) var partnerConnectionRepository
    @Dependency(\.currentUserId) var currentUserId
    @Dependency(\.notificationSettingsStore) var notificationSettingsStore
    @Dependency(\.notificationSettingsRepository) var notificationSettingsRepository
    @Dependency(\.notificationService) var notificationService

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.notificationSettings = notificationSettingsStore.load()
                guard let userId = currentUserId() else {
                    state.isLoadingPartner = false
                    state.isConnected = false
                    return .run { send in
                        await send(.notificationPermissionLoaded(await notificationService.permissionStatus()))
                    }
                }
                return .merge(
                    .run { send in
                        await send(.loadPartnerResponse(Result {
                            try await fetchEffectivePartnerUseCase.execute(userId: userId)
                        }))
                        let connection = try? await partnerConnectionRepository.fetchConnection(userId: userId)
                        await send(.connectionChecked(connection != nil))
                    },
                    .run { send in
                        await send(.notificationPermissionLoaded(await notificationService.permissionStatus()))
                    },
                    .run { send in
                        await send(.notificationSettingsResponse(Result {
                            try await notificationSettingsRepository.fetch(userId: userId)
                        }))
                    }
                )

            case .connectionChecked(let isConnected):
                state.isConnected = isConnected
                return .none

            case .notificationPermissionLoaded(let status):
                state.notificationPermissionStatus = status
                return .none

            case .notificationSettingsResponse(.success(let settings)):
                state.notificationSettings = settings
                return .run { _ in
                    notificationSettingsStore.save(settings)
                    if !settings.pushEnabled || !settings.courseReminderEnabled {
                        await notificationService.cancelCourseNotifications()
                    }
                    if !settings.pushEnabled || !settings.anniversaryEnabled {
                        await notificationService.cancelAnniversaryNotifications()
                    }
                }

            case .notificationSettingsResponse(.failure):
                return .none

            case .loadPartnerResponse(.success(let partner)):
                state.partner = partner
                state.isLoadingPartner = false
                return .none

            case .loadPartnerResponse(.failure):
                state.isLoadingPartner = false
                return .none

            case .profileTapped:
                return .send(.delegate(.openProfile))

            case .partnerTapped:
                return .send(.delegate(.openPartner(state.partner, isConnected: state.isConnected)))

            case .anniversaryTapped:
                return .send(.delegate(.openAnniversary))

            case .wishlistTapped:
                return .send(.delegate(.openWishlist))

            case .checklistTapped:
                return .send(.delegate(.openChecklist))

            case .tasteMapTapped:
                return .send(.delegate(.openTasteMap))

            case .pushNotificationToggled(let enabled):
                if enabled, state.notificationPermissionStatus == .denied {
                    state.alert = AlertState {
                        TextState("알림 권한이 꺼져 있어요")
                    } actions: {
                        ButtonState(action: .openSystemNotificationSettings) {
                            TextState("설정 열기")
                        }
                        ButtonState(role: .cancel) {
                            TextState("취소")
                        }
                    } message: {
                        TextState("iPhone 설정에서 ForP 알림을 허용한 뒤 다시 켜주세요.")
                    }
                    return .none
                }
                state.notificationSettings.pushEnabled = enabled
                let settings = state.notificationSettings
                let userId = currentUserId()
                return .run { send in
                    notificationSettingsStore.save(settings)
                    if let userId {
                        try? await notificationSettingsRepository.save(userId: userId, settings: settings)
                    }
                    if enabled {
                        if await notificationService.permissionStatus() == .notDetermined {
                            _ = await notificationService.requestPermission()
                        }
                        await send(.notificationPermissionLoaded(await notificationService.permissionStatus()))
                    } else {
                        await notificationService.cancelCourseNotifications()
                        await notificationService.cancelAnniversaryNotifications()
                    }
                }

            case .courseReminderToggled(let enabled):
                state.notificationSettings.courseReminderEnabled = enabled
                let settings = state.notificationSettings
                let userId = currentUserId()
                return .run { _ in
                    notificationSettingsStore.save(settings)
                    if let userId {
                        try? await notificationSettingsRepository.save(userId: userId, settings: settings)
                    }
                    if !enabled || !settings.pushEnabled {
                        await notificationService.cancelCourseNotifications()
                    }
                }

            case .anniversaryNotificationToggled(let enabled):
                state.notificationSettings.anniversaryEnabled = enabled
                let settings = state.notificationSettings
                let userId = currentUserId()
                return .run { _ in
                    notificationSettingsStore.save(settings)
                    if let userId {
                        try? await notificationSettingsRepository.save(userId: userId, settings: settings)
                    }
                    if !enabled || !settings.pushEnabled {
                        await notificationService.cancelAnniversaryNotifications()
                    }
                }

            case .partnerNotificationToggled(let enabled):
                state.notificationSettings.partnerEnabled = enabled
                let settings = state.notificationSettings
                let userId = currentUserId()
                return .run { _ in
                    notificationSettingsStore.save(settings)
                    if let userId {
                        try? await notificationSettingsRepository.save(userId: userId, settings: settings)
                    }
                }

            case .partnerConnectTapped:
                return .send(.delegate(.openPartnerConnect))

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
                guard let userId = currentUserId() else {
                    state.alert = AlertState { TextState("초기화 실패") } actions: {
                        ButtonState(role: .cancel) { TextState("확인") }
                    } message: {
                        TextState("로그인 상태를 확인한 뒤 다시 시도해주세요.")
                    }
                    return .none
                }
                state.isLoading = true
                return .run { send in
                    await send(.resetPartnerResponse(Result {
                        try await partnerRepository.deletePartner(forUserId: userId)
                        if let conn = try? await partnerConnectionRepository.fetchConnection(userId: userId) {
                            try await partnerConnectionRepository.disconnect(connectionId: conn.id)
                        }
                    }))
                }

            case .alert(.presented(.confirmLogout)):
                state.isLoading = true
                return .run { send in
                    await send(.logoutResponse(
                        Result { try await authRepository.logout() }
                    ))
                }

            case .alert(.presented(.confirmDeleteAccount)):
                state.isLoading = true
                return .run { send in
                    await send(.deleteAccountResponse(
                        Result { try await authRepository.deleteAccount() }
                    ))
                }

            case .alert(.presented(.openSystemNotificationSettings)):
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return .none }
                return .run { _ in
                    await UIApplication.shared.open(url)
                }

            case .alert:
                return .none

            case .resetPartnerResponse(.success):
                state.isLoading = false
                state.partner = nil
                return .none

            case .resetPartnerResponse(.failure(let error)):
                state.isLoading = false
                state.alert = AlertState { TextState("오류") } actions: { ButtonState(role: .cancel) { TextState("확인") } } message: { TextState(error.localizedDescription) }
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

            case .deleteAccountTapped:
                state.alert = AlertState {
                    TextState("계정 삭제")
                } actions: {
                    ButtonState(role: .destructive, action: .confirmDeleteAccount) {
                        TextState("삭제")
                    }
                    ButtonState(role: .cancel) {
                        TextState("취소")
                    }
                } message: {
                    TextState("계정과 저장된 코스, 찜 목록, 파트너 정보가 삭제됩니다. 이 작업은 되돌릴 수 없습니다.")
                }
                return .none

            case .deleteAccountResponse(.success):
                state.isLoading = false
                return .send(.delegate(.loggedOut))

            case .deleteAccountResponse(.failure(let error)):
                state.isLoading = false
                state.alert = AlertState { TextState("계정 삭제 실패") } actions: { ButtonState(role: .cancel) { TextState("확인") } } message: { TextState(error.localizedDescription) }
                return .none

            case .delegate:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}
