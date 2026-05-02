import ComposableArchitecture
import Domain

@Reducer
public struct OnboardingFeature {
    @ObservableState
    public struct State: Equatable {
        public var user: User
        public var nickname = ""
        public var location = ""
        public var locationSuggestions: [CoursePlace] = []
        public var isSearchingLocation = false
        public var selectedLocation: CoursePlace?
        public var preferredCategories: [String] = []
        public var dislikedCategories: [String] = []
        public var foodBlacklist: [String] = []
        public var preferredThemes: [String] = []
        public var isLoading = false
        @Presents public var alert: AlertState<Action.Alert>?

        public init(user: User) {
            self.user = user
            self.nickname = user.nickname
            self.location = user.location
        }
    }

    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case onAppear
        case randomNicknameTapped
        case categoryTapped(String)
        case blacklistToggled(String)
        case blacklistCustomAdded(String)
        case blacklistRemoved(String)
        case locationSearchDebounced
        case locationSuggestionsLoaded([CoursePlace])
        case locationSuggestionSelected(CoursePlace)
        case selectedLocationCleared
        case themeToggled(String)
        case saveTapped
        case saveResponse(Result<Void, Error>)
        case alert(PresentationAction<Alert>)
        case delegate(Delegate)

        public enum Alert: Equatable {}

        public enum Delegate: Equatable { case onboardingCompleted(User) }
    }

    @Dependency(\.userRepository) var userRepository
    @Dependency(\.placeRepository) var placeRepository

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return .none }
                state.nickname = Self.makeRandomNickname()
                return .none

            case .randomNicknameTapped:
                state.nickname = Self.makeRandomNickname()
                return .none

            case .binding(\.location):
                state.selectedLocation = nil
                state.locationSuggestions = []
                guard state.location.count >= 2 else {
                    state.isSearchingLocation = false
                    return .cancel(id: "onboardingLocationSearch")
                }
                state.isSearchingLocation = true
                return .run { send in
                    try? await Task.sleep(nanoseconds: 350_000_000)
                    await send(.locationSearchDebounced)
                }
                .cancellable(id: "onboardingLocationSearch", cancelInFlight: true)

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
                return .cancel(id: "onboardingLocationSearch")

            case .selectedLocationCleared:
                state.selectedLocation = nil
                state.location = ""
                state.locationSuggestions = []
                state.isSearchingLocation = false
                return .cancel(id: "onboardingLocationSearch")

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

            case .blacklistToggled(let item):
                if state.foodBlacklist.contains(item) {
                    state.foodBlacklist.removeAll { $0 == item }
                } else {
                    state.foodBlacklist.append(item)
                }
                return .none

            case .blacklistCustomAdded(let item):
                let trimmed = item.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty, !state.foodBlacklist.contains(trimmed) else { return .none }
                state.foodBlacklist.append(trimmed)
                return .none

            case .blacklistRemoved(let item):
                state.foodBlacklist.removeAll { $0 == item }
                return .none

            case .themeToggled(let item):
                state.preferredThemes.toggle(item)
                return .none

            case .saveTapped:
                guard !state.nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    state.alert = AlertState { TextState("닉네임을 입력해주세요") } actions: { ButtonState(role: .cancel) { TextState("확인") } } message: { TextState("앱에서 사용할 닉네임을 입력해주세요") }
                    return .none
                }
                guard !state.location.trimmingCharacters(in: .whitespaces).isEmpty else {
                    state.alert = AlertState { TextState("지역을 입력해주세요") } actions: { ButtonState(role: .cancel) { TextState("확인") } } message: { TextState("주로 데이트하는 동네를 입력해주세요") }
                    return .none
                }
                guard state.selectedLocation != nil else {
                    state.alert = AlertState { TextState("지역을 선택해주세요") } actions: { ButtonState(role: .cancel) { TextState("확인") } } message: { TextState("검색 결과에서 자주 가는 동네를 선택해주세요") }
                    return .none
                }
                guard !state.preferredCategories.isEmpty || !state.dislikedCategories.isEmpty else {
                    state.alert = AlertState { TextState("취향을 선택해주세요") } actions: { ButtonState(role: .cancel) { TextState("확인") } } message: { TextState("좋아하거나 피하고 싶은 카테고리를 하나 이상 선택해주세요") }
                    return .none
                }
                guard !state.preferredThemes.isEmpty else {
                    state.alert = AlertState { TextState("분위기를 선택해주세요") } actions: { ButtonState(role: .cancel) { TextState("확인") } } message: { TextState("선호하는 데이트 분위기를 하나 이상 선택해주세요") }
                    return .none
                }
                state.isLoading = true
                var user = state.user
                user.nickname = state.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
                user.preferredCategories = state.preferredCategories
                user.dislikedCategories = state.dislikedCategories
                user.foodBlacklist = state.foodBlacklist
                user.preferredThemes = state.preferredThemes
                user.location = state.location
                return .run { [user] send in
                    await send(.saveResponse(
                        Result { try await userRepository.updateUser(user) }
                    ))
                }

            case .saveResponse(.success):
                state.isLoading = false
                var user = state.user
                user.nickname = state.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
                user.preferredCategories = state.preferredCategories
                user.dislikedCategories = state.dislikedCategories
                user.foodBlacklist = state.foodBlacklist
                user.preferredThemes = state.preferredThemes
                user.location = state.location
                return .send(.delegate(.onboardingCompleted(user)))

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

    private static func makeRandomNickname() -> String {
        let prefixes = [
            "설레는", "즉흥적인", "감성적인", "맛잘알", "주말의", "다정한", "로맨틱한", "산책하는",
            "취향저격", "포근한", "느긋한", "반짝이는", "달콤한", "따뜻한", "활기찬", "차분한",
            "기분좋은", "새로운", "여유로운", "센스있는", "귀여운", "특별한", "소소한", "햇살같은",
            "한적한", "즐거운", "낭만적인", "부지런한", "호기심많은", "편안한",
        ]
        let moods = [
            "카페", "브런치", "노을", "골목", "한강", "전시", "영화", "피크닉",
            "디저트", "야경", "산책", "맛집", "드라이브", "주말", "데이트", "여행",
            "루프탑", "공원", "서점", "재즈", "와인", "라떼", "꽃길", "감성",
        ]
        let nouns = [
            "파트너", "데이트러", "탐험가", "산책러", "로맨티스트", "코스메이트", "맛잘알",
            "여행자", "플래너", "무드러버", "수집가", "발견자", "길잡이", "메이트",
            "큐레이터", "기록가", "모험가", "취향러", "나들이러", "코스러",
        ]
        let suffix = Int.random(in: 10...9999)
        let formats: [() -> String] = [
            { "\(prefixes.randomElement() ?? "설레는") \(nouns.randomElement() ?? "파트너") \(suffix)" },
            { "\(moods.randomElement() ?? "데이트") \(nouns.randomElement() ?? "메이트") \(suffix)" },
            { "\(prefixes.randomElement() ?? "감성적인") \(moods.randomElement() ?? "카페") \(nouns.randomElement() ?? "탐험가")" },
        ]
        return formats.randomElement()?() ?? "설레는 파트너 \(suffix)"
    }
}

private extension Array where Element == String {
    mutating func toggle(_ item: String) {
        if contains(item) { removeAll { $0 == item } }
        else { append(item) }
    }
}

private extension String {
    var locationKey: String {
        self.folding(options: [.caseInsensitive, .widthInsensitive], locale: .current)
            .components(separatedBy: .whitespacesAndNewlines)
            .joined()
    }
}
