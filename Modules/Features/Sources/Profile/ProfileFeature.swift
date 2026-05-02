import ComposableArchitecture
import Domain

@Reducer
public struct ProfileFeature {
    @ObservableState
    public struct State: Equatable {
        var originalUser: User
        public var nickname: String
        public var location: String
        public var locationSuggestions: [CoursePlace] = []
        public var isSearchingLocation = false
        public var selectedLocation: CoursePlace?
        public var preferredCategories: [String]
        public var dislikedCategories: [String]
        public var preferredThemes: [String]
        public var foodBlacklist: [String]
        public var isSaving = false
        public var showSaved = false

        public var hasChanges: Bool {
            nickname != originalUser.nickname ||
            location != originalUser.location ||
            preferredCategories != originalUser.preferredCategories ||
            dislikedCategories != originalUser.dislikedCategories ||
            preferredThemes != originalUser.preferredThemes ||
            foodBlacklist != originalUser.foodBlacklist
        }
        @Presents public var alert: AlertState<Action.Alert>?

        public init(user: User) {
            self.originalUser = user
            self.nickname = user.nickname
            self.location = user.location
            if !user.location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                self.selectedLocation = CoursePlace(
                    order: 0,
                    category: "",
                    keyword: user.location,
                    reason: "",
                    placeName: user.location
                )
            }
            self.preferredCategories = user.preferredCategories
            self.dislikedCategories = user.dislikedCategories
            self.preferredThemes = user.preferredThemes
            self.foodBlacklist = user.foodBlacklist
        }
    }

    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case locationSearchDebounced
        case locationSuggestionsLoaded([CoursePlace])
        case locationSuggestionSelected(CoursePlace)
        case selectedLocationCleared
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
    @Dependency(\.placeRepository) var placeRepository

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding(\.location):
                state.selectedLocation = nil
                state.locationSuggestions = []
                guard state.location.count >= 2 else {
                    state.isSearchingLocation = false
                    return .cancel(id: "profileLocationSearch")
                }
                state.isSearchingLocation = true
                return .run { send in
                    try? await Task.sleep(nanoseconds: 350_000_000)
                    await send(.locationSearchDebounced)
                }
                .cancellable(id: "profileLocationSearch", cancelInFlight: true)

            case .binding:
                return .none

            case .locationSearchDebounced:
                let query = state.location
                return .run { [placeRepository] send in
                    let results = (try? await placeRepository.searchPlaces(keyword: query)) ?? []
                    await send(.locationSuggestionsLoaded(results))
                }

            case .locationSuggestionsLoaded(let places):
                state.isSearchingLocation = false
                var seen = Set<String>()
                let deduped = places.filter { place in
                    let key = (place.placeName ?? place.keyword).locationKey
                    if seen.contains(key) { return false }
                    seen.insert(key)
                    return true
                }
                state.locationSuggestions = Array(deduped.prefix(5))
                return .none

            case .locationSuggestionSelected(let place):
                state.selectedLocation = place
                state.location = place.placeName ?? place.keyword
                state.locationSuggestions = []
                state.isSearchingLocation = false
                return .cancel(id: "profileLocationSearch")

            case .selectedLocationCleared:
                state.selectedLocation = nil
                state.location = ""
                state.locationSuggestions = []
                state.isSearchingLocation = false
                return .cancel(id: "profileLocationSearch")

            case .saveTapped:
                guard !state.nickname.isEmpty else { return .none }
                let didChangeLocation = state.location != state.originalUser.location
                guard !didChangeLocation || state.selectedLocation != nil else {
                    state.alert = AlertState { TextState("지역을 선택해주세요") } actions: {
                        ButtonState(role: .cancel) { TextState("확인") }
                    } message: {
                        TextState("검색 결과에서 자주 가는 지역을 선택해주세요.")
                    }
                    return .none
                }
                var user = state.originalUser
                user.nickname = state.nickname
                user.location = state.location
                user.preferredCategories = state.preferredCategories
                user.dislikedCategories = state.dislikedCategories
                user.preferredThemes = state.preferredThemes
                user.foodBlacklist = state.foodBlacklist
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

private extension String {
    var locationKey: String {
        self.folding(options: [.caseInsensitive, .widthInsensitive], locale: .current)
            .components(separatedBy: .whitespacesAndNewlines)
            .joined()
    }
}
