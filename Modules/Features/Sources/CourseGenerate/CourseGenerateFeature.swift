import Foundation
import ComposableArchitecture
import Domain

@Reducer
public struct CourseGenerateFeature {
    @ObservableState
    public struct State: Equatable {
        public var user: User
        public var partner: Partner?
        public var locationQuery = ""
        public var selectedLocations: [CoursePlace] = []
        public var locationSuggestions: [CoursePlace] = []
        public var isSearchingLocation = false
        public var selectedThemes: [String] = []
        public var placeCount = 3
        public var memo = ""
        public var date: Date = Date()
        public var isGenerating = false
        public var errorMessage: String? = nil
        public var wishlistPlaces: [WishlistPlace] = []
        public var selectedWishlistIds: Set<UUID> = []

        public init(user: User, partner: Partner? = nil) {
            self.user = user
            self.partner = partner
            self.selectedThemes = user.preferredThemes
            let savedLocation = user.location.trimmingCharacters(in: .whitespacesAndNewlines)
            if !savedLocation.isEmpty {
                self.selectedLocations = [
                    CoursePlace(
                        order: 0,
                        category: "",
                        keyword: savedLocation,
                        reason: "",
                        placeName: savedLocation
                    )
                ]
            }
        }
    }

    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case generateTapped
        case generateResponse(Result<CoursePlan, Error>)
        case delegate(Delegate)
        case onAppear
        case wishlistLoaded([WishlistPlace])
        case toggleWishlistPlace(UUID)
        case removeFromWishlist(UUID)
        case locationSearchDebounced
        case locationSuggestionsLoaded([CoursePlace])
        case locationSuggestionSelected(CoursePlace)
        case removeSelectedLocation(Int)
        case retryTapped
        case cancelGenerationTapped

        public enum Delegate: Equatable {
            case courseGenerated(CoursePlan, CourseOptions)
            case userUpdated(User)
        }
    }

    @Dependency(\.generateCourseUseCase) var generateCourseUseCase
    @Dependency(\.wishlistRepository) var wishlistRepository
    @Dependency(\.currentUserId) var currentUserId
    @Dependency(\.userRepository) var userRepository
    @Dependency(\.placeRepository) var placeRepository

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding(\.locationQuery):
                state.locationSuggestions = []
                guard state.locationQuery.count >= 2 else {
                    state.isSearchingLocation = false
                    return .cancel(id: "locationSearch")
                }
                state.isSearchingLocation = true
                return .run { send in
                    try? await Task.sleep(nanoseconds: 350_000_000)
                    await send(.locationSearchDebounced)
                }
                .cancellable(id: "locationSearch", cancelInFlight: true)

            case .locationSearchDebounced:
                let query = state.locationQuery
                return .run { [placeRepository] send in
                    let results = (try? await placeRepository.searchPlaces(keyword: query)) ?? []
                    await send(.locationSuggestionsLoaded(results))
                }

            case .locationSuggestionsLoaded(let places):
                state.isSearchingLocation = false
                let selectedKeys = Set(state.selectedLocations.compactMap { $0.placeName?.locationKey })
                // 1차: 정규화된 이름으로 exact dedup
                var seen = Set<String>()
                var deduped = places.filter { place in
                    let key = (place.placeName ?? place.keyword).locationKey
                    if seen.contains(key) || selectedKeys.contains(key) { return false }
                    seen.insert(key)
                    return true
                }
                // 2차: 다른 항목의 prefix인 경우 제거 (예: "홍대입구역 2호선 1번출구" → "홍대입구역 2호선"의 중복)
                deduped = deduped.filter { place in
                    let key = (place.placeName ?? place.keyword).locationKey
                    return !deduped.contains { other in
                        let otherKey = (other.placeName ?? other.keyword).locationKey
                        return otherKey != key && key.hasPrefix(otherKey)
                    }
                }
                state.locationSuggestions = Array(deduped.prefix(5))
                return .none

            case .locationSuggestionSelected(let place):
                guard state.selectedLocations.count < 3 else { return .none }
                state.selectedLocations.append(place)
                state.locationQuery = ""
                state.locationSuggestions = []
                state.isSearchingLocation = false
                return .none

            case .removeSelectedLocation(let index):
                guard state.selectedLocations.indices.contains(index) else { return .none }
                state.selectedLocations.remove(at: index)
                return .none

            case .binding:
                return .none

            case .onAppear:
                let userId = currentUserId()
                return .run { [wishlistRepository] send in
                    let places = (try? await wishlistRepository.fetchAll(userId: userId)) ?? []
                    await send(.wishlistLoaded(places))
                }

            case .wishlistLoaded(let places):
                state.wishlistPlaces = places
                return .none

            case .toggleWishlistPlace(let id):
                if state.selectedWishlistIds.contains(id) {
                    state.selectedWishlistIds.remove(id)
                } else if state.selectedWishlistIds.count < 3 {
                    state.selectedWishlistIds.insert(id)
                }
                return .none

            case .removeFromWishlist(let id):
                state.wishlistPlaces.removeAll { $0.id == id }
                state.selectedWishlistIds.remove(id)
                return .run { [wishlistRepository] _ in
                    try? await wishlistRepository.delete(id: id)
                }

            case .generateTapped:
                state.isGenerating = true
                state.locationSuggestions = []
                let locationStr = state.selectedLocations.map { $0.placeName ?? $0.keyword }.joined(separator: ", ")
                let lats = state.selectedLocations.compactMap { $0.latitude }
                let lons = state.selectedLocations.compactMap { $0.longitude }
                let baseLat = lats.isEmpty ? nil : lats.reduce(0, +) / Double(lats.count)
                let baseLon = lons.isEmpty ? nil : lons.reduce(0, +) / Double(lons.count)

                // 선택 위치 스프레드 기반 동적 반경 계산
                let searchRadius: Int = {
                    guard let bl = baseLat, let bln = baseLon, lats.count > 1 else { return 2000 }
                    let maxSpreadMeters = zip(lats, lons).map { lat, lon -> Double in
                        let dlat = lat - bl
                        let dlon = (lon - bln) * cos(bl * .pi / 180)
                        return sqrt(dlat * dlat + dlon * dlon) * 111_000
                    }.max() ?? 0
                    return min(max(Int(maxSpreadMeters) + 1_000, 1_500), 3_000)
                }()

                let selectedWishlist = state.wishlistPlaces.filter { state.selectedWishlistIds.contains($0.id) }
                let options = CourseOptions(
                    location: locationStr,
                    themes: state.selectedThemes,
                    placeCount: state.placeCount,
                    mode: .ordered,
                    memo: state.memo,
                    date: state.date,
                    wishlistPlaces: selectedWishlist,
                    baseLatitude: baseLat,
                    baseLongitude: baseLon,
                    searchRadius: searchRadius
                )
                return .run { [options, user = state.user, partner = state.partner] send in
                    await send(.generateResponse(
                        Result { try await generateCourseUseCase.execute(user: user, partner: partner, options: options) }
                    ))
                }
                .cancellable(id: "courseGeneration", cancelInFlight: true)

            case .generateResponse(.success(let plan)):
                // isGenerating을 false로 하지 않아야 navigation 전 깜빡임 방지
                let locationStr = state.selectedLocations.map { $0.placeName ?? $0.keyword }.joined(separator: ", ")
                let selectedWishlist = state.wishlistPlaces.filter { state.selectedWishlistIds.contains($0.id) }
                let options = CourseOptions(
                    location: locationStr,
                    themes: state.selectedThemes,
                    placeCount: state.placeCount,
                    mode: .ordered,
                    memo: state.memo,
                    date: state.date,
                    wishlistPlaces: selectedWishlist
                )
                if !state.selectedThemes.isEmpty {
                    var updatedUser = state.user
                    let merged = state.selectedThemes + updatedUser.preferredThemes.filter { !state.selectedThemes.contains($0) }
                    updatedUser.preferredThemes = Array(merged.prefix(5))
                    state.user = updatedUser
                    return .merge(
                        .send(.delegate(.courseGenerated(plan, options))),
                        .send(.delegate(.userUpdated(updatedUser))),
                        .run { [updatedUser, userRepository] _ in
                            try? await userRepository.updateUser(updatedUser)
                        }
                    )
                }
                return .send(.delegate(.courseGenerated(plan, options)))

            case .generateResponse(.failure(let error)):
                state.isGenerating = false
                if let courseError = error as? CourseGenerationError {
                    state.errorMessage = courseError.errorDescription
                } else {
                    state.errorMessage = "코스 생성 중 오류가 발생했어요. 잠시 후 다시 시도해주세요."
                }
                return .none

            case .retryTapped:
                state.errorMessage = nil
                return .send(.generateTapped)

            case .cancelGenerationTapped:
                state.isGenerating = false
                return .cancel(id: "courseGeneration")

            case .delegate:
                return .none
            }
        }
    }
}

private extension String {
    // 유니코드 정규화 + 공백 제거 → 중복 판단 키
    var locationKey: String {
        self.folding(options: [.caseInsensitive, .widthInsensitive], locale: .current)
            .components(separatedBy: .whitespacesAndNewlines)
            .joined()
    }
}
