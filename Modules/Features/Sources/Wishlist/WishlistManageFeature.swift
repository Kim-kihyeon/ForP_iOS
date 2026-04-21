import ComposableArchitecture
import Domain
import Foundation

@Reducer
public struct WishlistManageFeature {
    @ObservableState
    public struct State: Equatable {
        public var places: [WishlistPlace] = []
        public var isLoading = false
        public var loadFailed = false

        public init() {}
    }

    public enum Action {
        case onAppear
        case loadResponse(Result<[WishlistPlace], Error>)
        case delete(IndexSet)
        case deleteResponse(Result<Void, Error>)
    }

    @Dependency(\.wishlistRepository) var wishlistRepository
    @Dependency(\.currentUserId) var currentUserId

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                state.loadFailed = false
                let userId = currentUserId()
                return .run { send in
                    await send(.loadResponse(
                        Result { try await wishlistRepository.fetchAll(userId: userId) }
                    ))
                }

            case .loadResponse(.success(let places)):
                state.isLoading = false
                state.places = places
                return .none

            case .loadResponse(.failure):
                state.isLoading = false
                state.loadFailed = true
                return .none

            case .delete(let offsets):
                let ids = offsets.map { state.places[$0].id }
                state.places.remove(atOffsets: offsets)
                return .run { send in
                    await send(.deleteResponse(Result {
                        for id in ids {
                            try await wishlistRepository.delete(id: id)
                        }
                    }))
                }

            case .deleteResponse:
                return .none
            }
        }
    }
}
