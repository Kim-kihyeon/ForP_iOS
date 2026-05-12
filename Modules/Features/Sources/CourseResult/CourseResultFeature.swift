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
        public var isRegenerating = false
        public var lockedPlaceKeys: Set<String> = []
        public var user: User?
        public var partner: Partner?
        public var generationOptions: CourseOptions?
        // 진행 모드
        public var isPlaying = false
        public var showLiveMap = false
        public var showDeparture = false
        public var showChecklist = false
        public var visitedOrders: Set<Int> = []
        public var showCompletion = false
        public var completionRating = 0
        public var completionReview = ""
        public var inProgressConflictCourse: Course? = nil

        public var allVisited: Bool {
            !course.places.isEmpty && course.places.allSatisfy { visitedOrders.contains($0.order) }
        }

        public var bookmarkedKeywords: Set<String> = []
        public var isCreator: Bool = true
        public var placeCountNote: String? = nil

        public var canPartiallyRegenerate: Bool {
            !isPlaying &&
                !course.isEnded &&
                !isRegenerating &&
                user != nil &&
                generationOptions != nil &&
                !lockedPlaceKeys.isEmpty &&
                lockedPlaceKeys.count < course.places.count
        }

        @Presents public var alert: AlertState<Action.Alert>?

        public init(
            course: Course,
            isSaved: Bool = false,
            user: User? = nil,
            partner: Partner? = nil,
            generationOptions: CourseOptions? = nil
        ) {
            self.course = course
            self.isSaved = isSaved
            self.user = user
            self.partner = partner
            self.generationOptions = generationOptions
            self.visitedOrders = Set(course.visitedOrders)
            self.isPlaying = course.status == .inProgress && !course.isEnded
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
        case inProgressCourseLoaded(Result<Course?, Error>)
        case startCourseResponse(Result<Void, Error>)
        case confirmReplaceInProgress
        case openConflictCourse
        case stopPlayTapped
        case departureTapped
        case departureDismissed
        case checklistTapped
        case checklistDismissed
        case liveMapDismissed
        case showLiveMapTapped
        case placeVisited(Int)
        case updateVisitedOrdersResponse(Result<Void, Error>)
        case saveReviewTapped
        case skipReviewTapped
        case updateRatingResponse(Result<Void, Error>)
        case endDateResponse(Result<Void, Error>)
        case persistCourseResponse(Result<Void, Error>)
        case redateTapped
        case leaveReviewTapped
        case courseEndedRemotely
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
        case togglePlaceLock(CoursePlace)
        case placeMemoChanged(Int, String)
        case placeMemoCommitted(Int)
        case partialRegenerateTapped
        case confirmedPartialRegenerate
        case cancelPartialRegenerationTapped
        case partialRegenerateResponse(Result<CoursePlan, Error>)

        public enum Alert: Equatable { case confirmDelete, retrySave, retryEndDate, confirmEndDate, confirmReplaceInProgress, openConflictCourse }
        public enum Delegate: Equatable {
            case dismiss
            case deleted
            case courseUpdated(Course)
            case redate(Course)
        }
    }

    @Dependency(\.saveCourseUseCase) var saveCourseUseCase
    @Dependency(\.courseRepository) var courseRepository
    @Dependency(\.wishlistRepository) var wishlistRepository
    @Dependency(\.currentUserId) var currentUserId
    @Dependency(\.notificationService) var notificationService
    @Dependency(\.notificationSettingsStore) var notificationSettingsStore
    @Dependency(\.generateCourseUseCase) var generateCourseUseCase

    private enum CancelID { case realtime }

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding(\.course.title):
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
                return .run { [notificationService, courseRepository] _ in
                    let settings = notificationSettingsStore.load()
                    if settings.pushEnabled, settings.courseReminderEnabled {
                        await notificationService.scheduleCourseNotification(for: course)
                    } else {
                        await notificationService.cancelCourseNotification(courseId: course.id)
                    }
                    if course.partnerId != nil {
                        await courseRepository.notifyPartner(courseId: course.id)
                    }
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

            case .alert(.presented(.confirmEndDate)):
                state.showLiveMap = false
                state.showCompletion = true
                return .none

            case .alert(.presented(.confirmReplaceInProgress)):
                return .send(.confirmReplaceInProgress)

            case .alert(.presented(.openConflictCourse)):
                return .send(.openConflictCourse)

            case .alert(.presented(.confirmDelete)):
                state.isDeleting = true
                let id = state.course.id
                return .run { send in
                    await send(.deleteResponse(
                        Result { try await courseRepository.deleteCourse(id: id) }
                    ))
                }

            case .alert(.presented(.retryEndDate)):
                let id = state.course.id
                return .run { send in
                    await send(.endDateResponse(Result {
                        try await courseRepository.endCourse(id: id)
                    }))
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
                return .merge(
                    .cancel(id: CancelID.realtime),
                    .run { _ in try? await courseRepository.updateTitle(id: id, title: title) }
                )

            case .startPlayTapped:
                guard state.isSaved, let userId = state.user?.id else {
                    state.isPlaying = true
                    state.showLiveMap = true
                    state.visitedOrders = []
                    state.course.visitedOrders = []
                    state.completionRating = 0
                    state.completionReview = ""
                    return .none
                }
                return .run { send in
                    await send(.inProgressCourseLoaded(
                        Result { try await courseRepository.fetchInProgressCourse(userId: userId) }
                    ))
                }

            case .inProgressCourseLoaded(.success(let active)):
                if let active, active.id != state.course.id {
                    state.inProgressConflictCourse = active
                    state.alert = AlertState {
                        TextState("진행 중인 데이트가 있어요")
                    } actions: {
                        ButtonState(action: .confirmReplaceInProgress) {
                            TextState("이 코스 시작")
                        }
                        ButtonState(action: .openConflictCourse) {
                            TextState("기존 코스로 돌아가기")
                        }
                        ButtonState(role: .cancel) {
                            TextState("취소")
                        }
                    } message: {
                        TextState("'\(active.title)'을 종료하고 이 코스를 시작할까요?")
                    }
                    return .none
                }

                if active?.id == state.course.id {
                    state.visitedOrders = Set(active?.visitedOrders ?? state.course.visitedOrders)
                    state.course.visitedOrders = Array(state.visitedOrders).sorted()
                } else {
                    state.visitedOrders = []
                    state.course.visitedOrders = []
                }
                state.isPlaying = true
                state.showLiveMap = true
                state.course.status = .inProgress
                state.course.isEnded = false
                state.completionRating = 0
                state.completionReview = ""
                let id = state.course.id
                let userId = state.user?.id
                let visited = state.course.visitedOrders
                return .run { send in
                    guard let userId else { return }
                    await send(.startCourseResponse(Result {
                        try await courseRepository.startCourse(id: id, userId: userId, visitedOrders: visited)
                    }))
                }

            case .inProgressCourseLoaded(.failure(let error)):
                state.alert = AlertState { TextState("시작 실패") } actions: {
                    ButtonState(role: .cancel) { TextState("확인") }
                } message: {
                    TextState(error.localizedDescription)
                }
                return .none

            case .confirmReplaceInProgress:
                let previousId = state.inProgressConflictCourse?.id
                state.inProgressConflictCourse = nil
                state.isPlaying = true
                state.showLiveMap = true
                state.visitedOrders = []
                state.course.visitedOrders = []
                state.course.status = .inProgress
                state.course.isEnded = false
                state.completionRating = 0
                state.completionReview = ""
                let id = state.course.id
                let userId = state.user?.id
                return .run { send in
                    await send(.startCourseResponse(Result {
                        if let previousId {
                            try await courseRepository.cancelCourse(id: previousId)
                        }
                        guard let userId else { return }
                        try await courseRepository.startCourse(id: id, userId: userId, visitedOrders: [])
                    }))
                }

            case .openConflictCourse:
                guard let course = state.inProgressConflictCourse else { return .none }
                state.inProgressConflictCourse = nil
                state.course = course
                state.isSaved = true
                state.isPlaying = course.status == .inProgress && !course.isEnded
                state.visitedOrders = Set(course.visitedOrders)
                state.showLiveMap = state.isPlaying
                return .none

            case .startCourseResponse(.success):
                return .none

            case .startCourseResponse(.failure(let error)):
                state.isPlaying = false
                state.showLiveMap = false
                state.course.status = state.course.isEnded ? .completed : .planned
                state.alert = AlertState { TextState("시작 실패") } actions: {
                    ButtonState(role: .cancel) { TextState("확인") }
                } message: {
                    TextState(error.localizedDescription)
                }
                return .none

            case .stopPlayTapped:
                if state.course.isEnded {
                    state.isPlaying = false
                    state.showLiveMap = false
                    state.visitedOrders = []
                    return .none
                }
                state.alert = AlertState {
                    TextState("데이트 종료")
                } actions: {
                    ButtonState(action: .confirmEndDate) { TextState("종료하기") }
                    ButtonState(role: .cancel) { TextState("계속하기") }
                } message: {
                    TextState("데이트를 종료할까요? 평점과 후기를 남길 수 있어요.")
                }
                return .none

            case .departureTapped:
                state.showDeparture = true
                return .none

            case .departureDismissed:
                state.showDeparture = false
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
                    if state.allVisited && !state.course.isEnded {
                        state.isPlaying = false
                        state.showLiveMap = false
                        state.showCompletion = true
                        state.course.isEnded = true
                        state.course.status = .completed
                    }
                }
                state.course.visitedOrders = Array(state.visitedOrders).sorted()
                let id = state.course.id
                let visited = state.course.visitedOrders
                let shouldComplete = state.course.status == .completed && state.course.isEnded
                guard state.isSaved else { return .none }
                return .run { send in
                    do {
                        try await courseRepository.updateVisitedOrders(id: id, visitedOrders: visited)
                        await send(.updateVisitedOrdersResponse(.success(())))
                        if shouldComplete {
                            await send(.endDateResponse(Result {
                                try await courseRepository.endCourse(id: id)
                            }))
                        }
                    } catch {
                        await send(.updateVisitedOrdersResponse(.failure(error)))
                    }
                }

            case .updateVisitedOrdersResponse(.success):
                return .none

            case .updateVisitedOrdersResponse(.failure(let error)):
                state.alert = AlertState { TextState("방문 기록 저장 실패") } actions: {
                    ButtonState(role: .cancel) { TextState("확인") }
                } message: {
                    TextState(error.localizedDescription)
                }
                return .none

            case .saveReviewTapped:
                state.showCompletion = false
                state.isPlaying = false
                state.showLiveMap = false
                let completedOrders = state.course.places.map(\.order).sorted()
                state.visitedOrders = Set(completedOrders)
                state.course.visitedOrders = completedOrders
                let rating = state.completionRating
                let review = state.completionReview.trimmingCharacters(in: .whitespacesAndNewlines)
                let isCreator = state.isCreator
                let id = state.course.id
                if isCreator {
                    state.course.rating = rating > 0 ? rating : nil
                    state.course.review = review.isEmpty ? nil : review
                } else {
                    state.course.partnerRating = rating > 0 ? rating : nil
                    state.course.partnerReview = review.isEmpty ? nil : review
                }
                state.course.isEnded = true
                state.course.status = .completed
                return .run { send in
                    if rating > 0 || !review.isEmpty {
                        await send(.updateRatingResponse(Result {
                            if isCreator {
                                try await courseRepository.updateRating(id: id, rating: rating > 0 ? rating : nil, review: review)
                            } else {
                                try await courseRepository.updatePartnerRating(id: id, rating: rating > 0 ? rating : nil, review: review)
                            }
                        }))
                    }
                    await send(.endDateResponse(Result {
                        try await courseRepository.endCourse(id: id)
                    }))
                }

            case .skipReviewTapped:
                state.showCompletion = false
                state.isPlaying = false
                state.showLiveMap = false
                let completedOrders = state.course.places.map(\.order).sorted()
                state.visitedOrders = Set(completedOrders)
                state.course.visitedOrders = completedOrders
                state.course.isEnded = true
                state.course.status = .completed
                let id = state.course.id
                return .run { send in
                    await send(.endDateResponse(Result {
                        try await courseRepository.endCourse(id: id)
                    }))
                }

            case .updateRatingResponse(.success):
                return .none

            case .updateRatingResponse(.failure(let error)):
                state.alert = AlertState { TextState("후기 저장 실패") } actions: {
                    ButtonState(role: .cancel) { TextState("확인") }
                } message: {
                    TextState(error.localizedDescription)
                }
                return .none

            case .endDateResponse(.success):
                return .none

            case .endDateResponse(.failure(let error)):
                state.alert = AlertState { TextState("완료 저장 실패") } actions: {
                    ButtonState(action: .retryEndDate) { TextState("다시 시도") }
                    ButtonState(role: .cancel) { TextState("확인") }
                } message: {
                    TextState(error.localizedDescription)
                }
                return .none

            case .redateTapped:
                return .send(.delegate(.redate(state.course)))

            case .leaveReviewTapped:
                state.completionRating = 0
                state.completionReview = ""
                state.showCompletion = true
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

            case .updateTitleResponse(.success):
                return .none

            case .updateTitleResponse(.failure(let error)):
                state.alert = AlertState { TextState("제목 저장 실패") } actions: {
                    ButtonState(role: .cancel) { TextState("확인") }
                } message: {
                    TextState(error.localizedDescription)
                }
                return .none

            case .reorderPlaces(let source, let destination):
                state.course.places.move(fromOffsets: source, toOffset: destination)
                state.course.places = state.course.places.enumerated().map { index, place in
                    var p = place; p.order = index + 1; return p
                }
                guard state.isSaved else { return .none }
                let course = state.course
                return .run { send in
                    await send(.persistCourseResponse(Result {
                        try await saveCourseUseCase.execute(course)
                    }))
                }

            case .resetPlaces(let places):
                state.course.places = places
                return .none

            case .removePlace(let offsets):
                state.course.places.remove(atOffsets: offsets)
                state.course.places = state.course.places.enumerated().map { index, place in
                    var p = place; p.order = index + 1; return p
                }
                guard state.isSaved else { return .none }
                let course = state.course
                return .run { send in
                    await send(.persistCourseResponse(Result {
                        try await saveCourseUseCase.execute(course)
                    }))
                }

            case .addCandidate(let place):
                var newPlace = place
                newPlace.order = state.course.places.count + 1
                state.course.places.append(newPlace)
                let addedKey = placeIdentityKey(place)
                state.course.candidates.removeAll { placeIdentityKey($0) == addedKey }
                state.course.candidates = state.course.candidates.enumerated().map { index, p in
                    var updated = p; updated.order = index + 1; return updated
                }
                guard state.isSaved else { return .none }
                let course = state.course
                return .run { send in
                    await send(.persistCourseResponse(Result {
                        try await saveCourseUseCase.execute(course)
                    }))
                }

            case .persistCourseResponse(.success):
                return .none

            case .persistCourseResponse(.failure(let error)):
                state.alert = AlertState { TextState("변경 저장 실패") } actions: {
                    ButtonState(role: .cancel) { TextState("확인") }
                } message: {
                    TextState(error.localizedDescription)
                }
                return .none

            case .onAppear:
                guard let userId = currentUserId() else { return .none }
                state.isCreator = state.course.userId == userId
                let courseId = state.course.id
                let shouldAutoComplete = state.isSaved &&
                    state.course.status == .inProgress &&
                    !state.course.isEnded &&
                    !state.course.places.isEmpty &&
                    state.course.places.allSatisfy { state.visitedOrders.contains($0.order) }
                if shouldAutoComplete {
                    state.course.isEnded = true
                    state.course.status = .completed
                    state.isPlaying = false
                    state.showLiveMap = false
                }
                let shouldSubscribe = state.isSaved && !state.course.isEnded
                return .merge(
                    .run { [wishlistRepository] send in
                        let all = (try? await wishlistRepository.fetchAll(userId: userId)) ?? []
                        await send(.bookmarksLoaded(all))
                    },
                    shouldAutoComplete ? .run { send in
                        await send(.endDateResponse(Result {
                            try await courseRepository.endCourse(id: courseId)
                        }))
                    } : .none,
                    shouldSubscribe ? .run { [courseRepository] send in
                        for await _ in courseRepository.observeIsEnded(courseId: courseId) {
                            await send(.courseEndedRemotely)
                        }
                    }.cancellable(id: CancelID.realtime) : .none
                )

            case .courseEndedRemotely:
                state.course.isEnded = true
                state.course.status = .completed
                state.isPlaying = false
                state.showLiveMap = false
                return .cancel(id: CancelID.realtime)

            case .bookmarksLoaded(let places):
                state.bookmarkedKeywords = Set(places.map { $0.keyword })
                return .none

            case .bookmarkPlace(let place):
                guard let userId = currentUserId() else {
                    state.alert = AlertState { TextState("찜 저장 실패") } actions: {
                        ButtonState(role: .cancel) { TextState("확인") }
                    } message: {
                        TextState("로그인 상태를 확인한 뒤 다시 시도해주세요.")
                    }
                    return .none
                }
                let isCurrentlyBookmarked = state.bookmarkedKeywords.contains(place.keyword)
                if !isCurrentlyBookmarked && state.bookmarkedKeywords.count >= 20 {
                    state.alert = AlertState { TextState("찜 목록이 가득 찼어요") } actions: { ButtonState(role: .cancel) { TextState("확인") } } message: { TextState("최대 20개까지 찜할 수 있어요. 기존 찜을 삭제한 후 다시 시도해주세요.") }
                    return .none
                }
                if isCurrentlyBookmarked {
                    state.bookmarkedKeywords.remove(place.keyword)
                    let keyword = place.keyword
                    return .run { [wishlistRepository] _ in
                        let all = (try? await wishlistRepository.fetchAll(userId: userId)) ?? []
                        if let existing = all.first(where: { $0.keyword == keyword }) {
                            try? await wishlistRepository.delete(id: existing.id)
                        }
                    }
                } else {
                    state.bookmarkedKeywords.insert(place.keyword)
                    let wp = WishlistPlace(userId: userId, keyword: place.keyword, placeName: place.placeName, address: place.address, latitude: place.latitude, longitude: place.longitude, category: place.category)
                    return .run { [wishlistRepository] _ in
                        try? await wishlistRepository.save(wp)
                    }
                }

            case .togglePlaceLock(let place):
                guard !state.isPlaying, !state.course.isEnded else { return .none }
                let key = placeIdentityKey(place)
                if state.lockedPlaceKeys.contains(key) {
                    state.lockedPlaceKeys.remove(key)
                } else {
                    state.lockedPlaceKeys.insert(key)
                }
                return .none

            case .placeMemoChanged(let order, let memo):
                guard let index = state.course.places.firstIndex(where: { $0.order == order }) else { return .none }
                let trimmed = memo.trimmingCharacters(in: .whitespacesAndNewlines)
                state.course.places[index].memo = trimmed.isEmpty ? nil : memo
                return .none

            case .placeMemoCommitted:
                guard state.isSaved else { return .none }
                let course = state.course
                return .run { send in
                    await send(.persistCourseResponse(Result {
                        try await saveCourseUseCase.execute(course)
                    }))
                }

            case .partialRegenerateTapped:
                guard state.canPartiallyRegenerate else { return .none }
                return .send(.confirmedPartialRegenerate)

            case .confirmedPartialRegenerate:
                guard state.canPartiallyRegenerate,
                      let user = state.user,
                      let options = state.generationOptions else {
                    return .none
                }
                let lockedKeys = state.lockedPlaceKeys
                let lockedPlaces = state.course.places.filter { lockedKeys.contains(placeIdentityKey($0)) }
                let excludedPlaces = state.course.places.filter { !lockedKeys.contains(placeIdentityKey($0)) }
                state.isRegenerating = true
                state.placeCountNote = nil

                var nextOptions = options
                nextOptions.placeCount = state.course.places.count
                nextOptions.date = state.course.date
                nextOptions.lockedPlaces = lockedPlaces
                nextOptions.excludedPlaces = excludedPlaces
                if nextOptions.baseLatitude == nil || nextOptions.baseLongitude == nil {
                    let lats = state.course.places.compactMap(\.latitude)
                    let lons = state.course.places.compactMap(\.longitude)
                    nextOptions.baseLatitude = lats.isEmpty ? nil : lats.reduce(0, +) / Double(lats.count)
                    nextOptions.baseLongitude = lons.isEmpty ? nil : lons.reduce(0, +) / Double(lons.count)
                }

                let requestOptions = nextOptions
                return .run { [generateCourseUseCase, partner = state.partner] send in
                    await send(.partialRegenerateResponse(
                        Result { try await generateCourseUseCase.execute(user: user, partner: partner, options: requestOptions) }
                    ))
                }
                .cancellable(id: "partialCourseRegeneration", cancelInFlight: true)

            case .cancelPartialRegenerationTapped:
                state.isRegenerating = false
                return .cancel(id: "partialCourseRegeneration")

            case .partialRegenerateResponse(.success(let plan)):
                state.isRegenerating = false
                let previousLockedKeys = state.lockedPlaceKeys
                state.course.places = plan.places
                state.course.candidates = plan.candidates
                state.course.outfitSuggestion = plan.outfitSuggestion
                state.course.courseReason = plan.courseReason
                state.lockedPlaceKeys = Set(plan.places
                    .filter { previousLockedKeys.contains(placeIdentityKey($0)) }
                    .map(placeIdentityKey))
                if let options = state.generationOptions, plan.places.count < options.placeCount {
                    state.placeCountNote = plan.candidates.isEmpty
                        ? "고정한 장소를 제외하고 새 장소를 충분히 찾지 못했어요."
                        : "요청한 수보다 적게 찾았어요. 후보 장소에서 추가할 수 있어요."
                }
                guard state.isSaved else { return .none }
                let course = state.course
                return .run { send in
                    await send(.persistCourseResponse(Result {
                        try await saveCourseUseCase.execute(course)
                    }))
                }

            case .partialRegenerateResponse(.failure(let error)):
                state.isRegenerating = false
                if let courseError = error as? CourseGenerationError {
                    state.alert = AlertState { TextState("다시 추천 실패") } actions: {
                        ButtonState(role: .cancel) { TextState("확인") }
                    } message: {
                        TextState(courseError.errorDescription ?? "조건을 조금 바꿔 다시 시도해주세요.")
                    }
                } else {
                    state.alert = AlertState { TextState("다시 추천 실패") } actions: {
                        ButtonState(role: .cancel) { TextState("확인") }
                    } message: {
                        TextState("고정한 장소를 유지한 채 다시 추천하지 못했어요. 잠시 후 다시 시도해주세요.")
                    }
                }
                return .none

            case .delegate:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

private func placeIdentityKey(_ place: CoursePlace) -> String {
    if let id = place.kakaoPlaceId, !id.isEmpty {
        return "id:\(id)"
    }
    let name = (place.placeName ?? place.keyword)
        .folding(options: [.caseInsensitive, .widthInsensitive], locale: .current)
        .components(separatedBy: .whitespacesAndNewlines)
        .joined()
    let address = (place.address ?? "")
        .folding(options: [.caseInsensitive, .widthInsensitive], locale: .current)
        .components(separatedBy: .whitespacesAndNewlines)
        .joined()
    return "text:\(name)|\(address)"
}
