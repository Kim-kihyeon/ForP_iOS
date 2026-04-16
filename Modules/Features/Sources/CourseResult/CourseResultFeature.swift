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
        public var visitedOrders: Set<Int> = []
        public var showCompletion = false
        public var completionRating = 0
        public var completionReview = ""

        public var allVisited: Bool {
            !course.places.isEmpty && course.places.allSatisfy { visitedOrders.contains($0.order) }
        }

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
        case placeVisited(Int)
        case saveReviewTapped
        case skipReviewTapped
        case updateRatingResponse(Result<Void, Error>)
        case titleCommitted
        case updateTitleResponse(Result<Void, Error>)
        case viewDisappeared

        public enum Alert: Equatable { case confirmDelete }
        public enum Delegate: Equatable {
            case dismiss
            case deleted
            case courseUpdated(Course)
        }
    }

    @Dependency(\.saveCourseUseCase) var saveCourseUseCase
    @Dependency(\.courseRepository) var courseRepository

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
                return .none

            case .saveResponse(.failure(let error)):
                state.isSaving = false
                state.alert = AlertState { TextState("오류") } actions: { ButtonState(role: .cancel) { TextState("확인") } } message: { TextState(error.localizedDescription) }
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
                return .send(.delegate(.deleted))

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
                state.visitedOrders = []
                state.completionRating = 0
                state.completionReview = ""
                return .none

            case .stopPlayTapped:
                state.isPlaying = false
                state.visitedOrders = []
                state.showCompletion = false
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

            case .delegate:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}
