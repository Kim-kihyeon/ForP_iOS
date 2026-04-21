import Foundation
import ComposableArchitecture
import Domain

@Reducer
public struct CourseGenerateFeature {
    @ObservableState
    public struct State: Equatable {
        public var user: User
        public var location = ""
        public var selectedThemes: [String] = []
        public var placeCount = 3
        public var memo = ""
        public var date: Date = Date()
        public var isGenerating = false
        public var errorMessage: String? = nil
        public var wishlistPlaces: [WishlistPlace] = []
        public var selectedWishlistIds: Set<UUID> = []

        public init(user: User) {
            self.user = user
            self.location = user.location
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

        public enum Delegate: Equatable {
            case courseGenerated(CoursePlan, CourseOptions)
        }
    }

    @Dependency(\.generateCourseUseCase) var generateCourseUseCase
    @Dependency(\.currentPartner) var currentPartner
    @Dependency(\.wishlistRepository) var wishlistRepository
    @Dependency(\.currentUserId) var currentUserId

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding(\.location):
                state.selectedWishlistIds = []
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
                let selectedWishlist = state.wishlistPlaces.filter { state.selectedWishlistIds.contains($0.id) }
                let options = CourseOptions(
                    location: state.location,
                    themes: state.selectedThemes,
                    placeCount: state.placeCount,
                    mode: .ordered,
                    memo: state.memo,
                    date: state.date,
                    wishlistPlaces: selectedWishlist
                )
                return .run { [options, user = state.user] send in
                    let partner = currentPartner()
                    await send(.generateResponse(
                        Result { try await generateCourseUseCase.execute(user: user, partner: partner, options: options) }
                    ))
                }

            case .generateResponse(.success(let plan)):
                state.isGenerating = false
                let selectedWishlist = state.wishlistPlaces.filter { state.selectedWishlistIds.contains($0.id) }
                let options = CourseOptions(
                    location: state.location,
                    themes: state.selectedThemes,
                    placeCount: state.placeCount,
                    mode: .ordered,
                    memo: state.memo,
                    date: state.date,
                    wishlistPlaces: selectedWishlist
                )
                return .send(.delegate(.courseGenerated(plan, options)))

            case .generateResponse(.failure(let error)):
                state.isGenerating = false
                state.errorMessage = error.localizedDescription
                return .none

            case .delegate:
                return .none
            }
        }
    }
}
