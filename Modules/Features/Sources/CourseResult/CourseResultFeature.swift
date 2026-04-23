import ComposableArchitecture
import Domain
import Foundation

@Reducer
public struct CourseResultFeature {
    @ObservableState
    public struct State: Equatable {
        public var course: Course
        public var isSaving = false
        public var isSaved: Bool
        public var isDeleting = false
        // 진행 모드
        public var isPlaying = false
        public var showLiveMap = false
        public var showDeparture = false
        public var showBudget = false
        public var showChecklist = false
        public var visitedOrders: Set<Int> = []
        public var showCompletion = false
        public var completionRating = 0
        public var completionReview = ""

        public var allVisited: Bool {
            !course.places.isEmpty && course.places.allSatisfy { visitedOrders.contains($0.order) }
        }

        public var bookmarkedKeywords: Set<String> = []

        @Presents public var alert: AlertState<Action.Alert>?

        public init(course: Course, isSaved: Bool = false) {
            self.course = course
            self.isSaved = isSaved
        }
    }

    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case saveTapped
        case saveResponse(Result<Void, Error>)
        case likeTapped
        case likeResponse(Result<Void, Error>)
        case deleteTapped
        case deleteResponse(Result<Void, Error>)
        case dismissTapped
        case alert(PresentationAction<Alert>)
        case delegate(Delegate)
        // 진행 모드
        case startPlayTapped
        case stopPlayTapped
        case departureTapped
        case departureDismissed
        case budgetTapped
        case budgetDismissed
        case checklistTapped
        case checklistDismissed
        case liveMapDismissed
        case showLiveMapTapped
        case placeVisited(Int)
        case saveReviewTapped
        case skipReviewTapped
        case updateRatingResponse(Result<Void, Error>)
        case titleCommitted
        case updateTitleResponse(Result<Void, Error>)
        case viewDisappeared
        case reorderPlaces(IndexSet, Int)
        case resetPlaces([CoursePlace])
        case removePlace(IndexSet)
        case addCandidate(CoursePlace)
        case onAppear
        case bookmarkPlace(CoursePlace)
        case bookmarksLoaded([WishlistPlace])

        public enum Alert: Equatable { case confirmDelete, retrySave }
        public enum Delegate: Equatable {
            case dismiss
            case deleted
            case courseUpdated(Course)
        }
    }

    @Dependency(\.saveCourseUseCase) var saveCourseUseCase
    @Dependency(\.courseRepository) var courseRepository
    @Dependency(\.wishlistRepository) var wishlistRepository
    @Dependency(\.currentUserId) var currentUserId
    @Dependency(\.notificationService) var notificationService

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding(\.course.title):
                if state.course.title.count > 10 {
                    state.course.title = String(state.course.title.prefix(10))
                }
                return .none

            case .binding:
                return .none

            case .saveTapped:
                state.isSaving = true
                let course = state.course
                return .run { send in
                    await send(.saveResponse(
                        Result { try await saveCourseUseCase.execute(course) }
                    ))
                }

            case .saveResponse(.success):
                state.isSaving = false
                state.isSaved = true
                let course = state.course
                return .run { [notificationService] _ in
                    await notificationService.scheduleCourseNotification(for: course)
                }

            case .saveResponse(.failure(let error)):
                state.isSaving = false
                state.alert = AlertState { TextState("저장 실패") } actions: {
                    ButtonState(action: .retrySave) { TextState("다시 시도") }
                    ButtonState(role: .cancel) { TextState("취소") }
                } message: { TextState(error.localizedDescription) }
                return .none

            case .likeTapped:
                guard state.isSaved else { return .none }
                let newValue = !state.course.isLiked
                state.course.isLiked = newValue
                let id = state.course.id
                return .run { send in
                    await send(.likeResponse(Result {
                        try await courseRepository.toggleLike(id: id, isLiked: newValue)
                    }))
                }

            case .likeResponse(.failure(let error)):
                state.course.isLiked = !state.course.isLiked
                state.alert = AlertState { TextState("오류") } actions: { ButtonState(role: .cancel) { TextState("확인") } } message: { TextState(error.localizedDescription) }
                return .none

            case .likeResponse(.success):
                return .none

            case .deleteTapped:
                state.alert = AlertState {
                    TextState("코스 삭제")
                } actions: {
                    ButtonState(role: .destructive, action: .confirmDelete) {
                        TextState("삭제")
                    }
                    ButtonState(role: .cancel) {
                        TextState("취소")
                    }
                } message: {
                    TextState("이 코스를 삭제할까요?")
                }
                return .none

            case .alert(.presented(.retrySave)):
                return .send(.saveTapped)

            case .alert(.presented(.confirmDelete)):
                state.isDeleting = true
                let id = state.course.id
                return .run { send in
                    await send(.deleteResponse(
                        Result { try await courseRepository.deleteCourse(id: id) }
                    ))
                }

            case .alert:
                return .none

            case .deleteResponse(.success):
                state.isDeleting = false
                let courseId = state.course.id
                return .run { [notificationService] send in
                    await notificationService.cancelCourseNotification(courseId: courseId)
                    await send(.delegate(.deleted))
                }

            case .deleteResponse(.failure(let error)):
                state.isDeleting = false
                state.alert = AlertState { TextState("오류") } actions: { ButtonState(role: .cancel) { TextState("확인") } } message: { TextState(error.localizedDescription) }
                return .none

            case .dismissTapped:
                return .send(.delegate(.dismiss))

            case .viewDisappeared:
                guard state.isSaved else { return .none }
                let id = state.course.id
                let title = state.course.title
                return .run { _ in
                    try? await courseRepository.updateTitle(id: id, title: title)
                }

            case .startPlayTapped:
                state.isPlaying = true
                state.showLiveMap = true
                state.visitedOrders = []
                state.completionRating = 0
                state.completionReview = ""
                return .none

            case .stopPlayTapped:
                state.isPlaying = false
                state.showLiveMap = false
                state.visitedOrders = []
                state.showCompletion = false
                return .none

            case .departureTapped:
                state.showDeparture = true
                return .none

            case .departureDismissed:
                state.showDeparture = false
                return .none

            case .budgetTapped:
                state.showBudget = true
                return .none

            case .budgetDismissed:
                state.showBudget = false
                return .none

            case .checklistTapped:
                state.showChecklist = true
                return .none

            case .checklistDismissed:
                state.showChecklist = false
                return .none

            case .liveMapDismissed:
                state.showLiveMap = false
                return .none

            case .showLiveMapTapped:
                state.showLiveMap = true
                return .none

            case .placeVisited(let order):
                if state.visitedOrders.contains(order) {
                    state.visitedOrders.remove(order)
                } else {
                    state.visitedOrders.insert(order)
                    if state.allVisited {
                        state.showCompletion = true
                    }
                }
                return .none

            case .saveReviewTapped:
                state.showCompletion = false
                state.isPlaying = false
                let rating = state.completionRating
                let review = state.completionReview
                state.course.rating = rating > 0 ? rating : nil
                state.course.review = review.isEmpty ? nil : review
                guard rating > 0 else { return .none }
                let id = state.course.id
                return .run { send in
                    await send(.updateRatingResponse(Result {
                        try await courseRepository.updateRating(id: id, rating: rating, review: review)
                    }))
                }

            case .skipReviewTapped:
                state.showCompletion = false
                state.isPlaying = false
                return .none

            case .updateRatingResponse:
                return .none

            case .titleCommitted:
                guard state.isSaved, !state.course.title.isEmpty else { return .none }
                let id = state.course.id
                let title = state.course.title
                return .run { send in
                    await send(.updateTitleResponse(Result {
                        try await courseRepository.updateTitle(id: id, title: title)
                    }))
                }

            case .updateTitleResponse:
                return .none

            case .reorderPlaces(let source, let destination):
                state.course.places.move(fromOffsets: source, toOffset: destination)
                state.course.places = state.course.places.enumerated().map { index, place in
                    var p = place; p.order = index + 1; return p
                }
                return .none

            case .resetPlaces(let places):
                state.course.places = places
                return .none

            case .removePlace(let offsets):
                state.course.places.remove(atOffsets: offsets)
                state.course.places = state.course.places.enumerated().map { index, place in
                    var p = place; p.order = index + 1; return p
                }
                return .none

            case .addCandidate(let place):
                var newPlace = place
                newPlace.order = state.course.places.count + 1
                state.course.places.append(newPlace)
                state.course.candidates.removeAll { $0.keyword == place.keyword }
                state.course.candidates = state.course.candidates.enumerated().map { index, p in
                    var updated = p; updated.order = index + 1; return updated
                }
                return .none

            case .onAppear:
                let userId = currentUserId()
                return .run { [wishlistRepository] send in
                    let all = (try? await wishlistRepository.fetchAll(userId: userId)) ?? []
                    await send(.bookmarksLoaded(all))
                }

            case .bookmarksLoaded(let places):
                state.bookmarkedKeywords = Set(places.map { $0.keyword })
                return .none

            case .bookmarkPlace(let place):
                let isCurrentlyBookmarked = state.bookmarkedKeywords.contains(place.keyword)
                if !isCurrentlyBookmarked && state.bookmarkedKeywords.count >= 20 {
                    state.alert = AlertState { TextState("찜 목록이 가득 찼어요") } actions: { ButtonState(role: .cancel) { TextState("확인") } } message: { TextState("최대 20개까지 찜할 수 있어요. 기존 찜을 삭제한 후 다시 시도해주세요.") }
                    return .none
                }
                if isCurrentlyBookmarked {
                    state.bookmarkedKeywords.remove(place.keyword)
                    let userId = currentUserId()
                    let keyword = place.keyword
                    return .run { [wishlistRepository] _ in
                        let all = (try? await wishlistRepository.fetchAll(userId: userId)) ?? []
                        if let existing = all.first(where: { $0.keyword == keyword }) {
                            try? await wishlistRepository.delete(id: existing.id)
                        }
                    }
                } else {
                    state.bookmarkedKeywords.insert(place.keyword)
                    let userId = currentUserId()
                    let wp = WishlistPlace(userId: userId, keyword: place.keyword, placeName: place.placeName, address: place.address, latitude: place.latitude, longitude: place.longitude, category: place.category)
                    return .run { [wishlistRepository] _ in
                        try? await wishlistRepository.save(wp)
                    }
                }

            case .delegate:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}
