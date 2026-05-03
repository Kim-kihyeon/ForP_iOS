import SwiftUI
import ComposableArchitecture
import CoreSharedUI
import Domain
import MapKit

public struct CourseResultView: View {
    @Bindable var store: StoreOf<CourseResultFeature>
    @FocusState private var titleFocused: Bool
    @State private var mapCameraPosition: MapCameraPosition = .automatic
    @State private var showCandidates = false
    @State private var tappedPlaceOrder: Int? = nil
    @State private var isReordering = false
    @State private var placesBeforeReorder: [CoursePlace] = []
    @State private var showExitConfirm = false

    private var coordinatePlaces: [(CoursePlace, CLLocationCoordinate2D)] {
        store.course.places.compactMap { place in
            guard let lat = place.latitude, let lon = place.longitude else { return nil }
            return (place, CLLocationCoordinate2D(latitude: lat, longitude: lon))
        }
    }

    private var shareText: String {
        let dateText: String = {
            let f = DateFormatter()
            f.locale = Locale(identifier: "ko_KR")
            f.dateFormat = "M월 d일 (E)"
            return f.string(from: store.course.date)
        }()
        let places = store.course.places
            .sorted { $0.order < $1.order }
            .map { "\($0.order). \($0.placeName ?? $0.keyword)" }
            .joined(separator: "\n")
        var text = "📍 \(store.course.title)\n\(dateText)\n\n\(places)"
        if let reason = store.course.courseReason.isEmpty ? nil : store.course.courseReason {
            text += "\n\n💡 \(reason)"
        }
        text += "\n\n— ForP 앱으로 만든 데이트 코스 🩷"
        return text
    }

    private var placeColors: [Color] {
        [Brand.pink, Brand.iconBlue, Brand.iconPurple, Brand.iconTeal, Brand.iconOrange, Brand.iconRed]
    }

    public init(store: StoreOf<CourseResultFeature>) {
        self.store = store
    }

    public var body: some View {
        baseView
            .alert($store.scope(state: \.alert, action: \.alert))
            .sheet(isPresented: $store.showCompletion) { completionSheet }
            .sheet(isPresented: Binding(
                get: { store.showLiveMap },
                set: { if !$0 { store.send(.liveMapDismissed) } }
            )) {
                CourseLiveMapView(
                    places: store.course.places,
                    visitedOrders: store.visitedOrders,
                    onVisit: { store.send(.placeVisited($0)) },
                    onDismiss: { store.send(.liveMapDismissed) },
                    onStop: { store.send(.stopPlayTapped) }
                )
                .ignoresSafeArea()
            }
            .sheet(isPresented: Binding(
                get: { store.showDeparture },
                set: { if !$0 { store.send(.departureDismissed) } }
            )) {
                DepartureCalculatorView(places: store.course.places)
            }
            .sheet(isPresented: Binding(
                get: { store.showChecklist },
                set: { if !$0 { store.send(.checklistDismissed) } }
            )) {
                ChecklistView()
            }
    }

    private var baseView: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    heroMap
                    mainContent
                }
                .padding(.bottom, 32)
            }
            if store.isSaving || store.isDeleting { LoadingView() }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !store.isSaved { saveButton }
            else if !store.isPlaying && !store.course.isEnded { startButton }
        }
        .navigationTitle(store.course.title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(!store.isSaved)
        .tint(Brand.pink)
        .toolbarBackground(Brand.softPink, for: .navigationBar)
        .disableSwipeBack()
        .onAppear { store.send(.onAppear) }
        .onDisappear { store.send(.viewDisappeared) }
        .alert("코스를 저장하지 않고 나갈까요?", isPresented: $showExitConfirm) {
            Button("나가기", role: .destructive) { store.send(.delegate(.dismiss)) }
            Button("취소", role: .cancel) {}
        } message: {
            Text("저장하지 않으면 이 코스가 사라져요.")
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if !store.isSaved {
                    Button {
                        showExitConfirm = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("뒤로")
                                .font(Typography.body)
                        }
                    }
                    .tint(Brand.pink)
                }
            }
            ToolbarItem(placement: .primaryAction) {
                if store.isPlaying {
                    HStack(spacing: 4) {
                        Button { store.send(.showLiveMapTapped) } label: {
                            Image(systemName: "map").font(.system(size: 15, weight: .medium))
                        }
                        .foregroundStyle(Brand.pink)
                        Button("종료") { store.send(.stopPlayTapped) }
                            .foregroundStyle(Brand.pink)
                    }
                } else if store.isSaved {
                    Menu {
                        Button {
                            Task {
                                guard let image = await renderShareCard() else { return }
                                let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
                                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                      let window = windowScene.windows.first else { return }
                                var topVC = window.rootViewController
                                while let presented = topVC?.presentedViewController { topVC = presented }
                                topVC?.present(activityVC, animated: true)
                            }
                        } label: {
                            Label("카드 이미지로 공유", systemImage: "photo")
                        }
                        ShareLink(item: shareText) {
                            Label("텍스트로 공유", systemImage: "doc.text")
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up").font(.system(size: 15, weight: .medium))
                    }
                    .tint(Brand.pink)
                }
            }
        }
    }

    // MARK: - Hero Map

    @ViewBuilder
    private var heroMap: some View {
        if !coordinatePlaces.isEmpty {
            let coords = coordinatePlaces.map { $0.1 }
            Map(position: $mapCameraPosition) {
                ForEach(Array(coordinatePlaces.enumerated()), id: \.element.0.order) { index, item in
                    Annotation(item.0.placeName ?? item.0.keyword, coordinate: item.1) {
                        ZStack {
                            Circle()
                                .fill(placeColors[index % placeColors.count])
                                .frame(width: 32, height: 32)
                                .shadow(color: .black.opacity(0.25), radius: 4)
                            Text("\(item.0.order)")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                    }
                }
                if coords.count > 1 {
                    MapPolyline(coordinates: coords)
                        .stroke(Brand.pink.opacity(0.8), lineWidth: 3)
                }
            }
            .frame(height: 280)
            .onAppear {
                mapCameraPosition = .region(mapRegion(for: coords))
            }
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        VStack(spacing: 16) {
            headerCard
            if store.course.isEnded && !store.isPlaying { endedBanner }
            if store.isPlaying { progressBar }
            timelinePlaces
            if !store.isPlaying { ratingsSection }
            if !store.course.candidates.isEmpty, !store.isPlaying {
                candidatesAccordion
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, 16)
    }

    private var endedBanner: some View {
        let myRating = store.isCreator ? store.course.rating : store.course.partnerRating
        let hasMyReview = myRating != nil

        return HStack(spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 16))
                .foregroundStyle(Brand.pink)
            VStack(alignment: .leading, spacing: 2) {
                Text("종료된 데이트")
                    .font(.system(size: 13, weight: .semibold))
                Text(hasMyReview ? "이 코스로 다시 데이트하시겠어요?" : "후기를 남겨보세요")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if hasMyReview {
                Button {
                    Haptics.impact(.medium)
                    store.send(.redateTapped)
                } label: {
                    Text("다시 데이트")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Brand.pink)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    Haptics.impact(.medium)
                    store.send(.leaveReviewTapped)
                } label: {
                    Text("리뷰 남기기")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Brand.pink)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Brand.softPink)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Spacing.md)
        .cardStyle()
    }

    @ViewBuilder
    private var ratingsSection: some View {
        let myRating = store.isCreator ? store.course.rating : store.course.partnerRating
        let myReview = store.isCreator ? store.course.review : store.course.partnerReview
        let partnerRating = store.isCreator ? store.course.partnerRating : store.course.rating
        let partnerReview = store.isCreator ? store.course.partnerReview : store.course.review

        if let r = myRating {
            ratingCard(label: "내 후기", rating: r, review: myReview)
        }
        if let r = partnerRating {
            ratingCard(label: "파트너 후기", rating: r, review: partnerReview)
        }
    }

    // MARK: - Header Card

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(store.isSaved ? "코스 이름" : "코스 이름을 정해주세요")
                        .font(Typography.caption2.weight(.semibold))
                        .foregroundStyle(store.isSaved ? .secondary : Brand.pink)
                    HStack(spacing: 6) {
                        TextField("코스 제목", text: $store.course.title)
                            .font(.system(size: 22, weight: .bold))
                            .focused($titleFocused)
                            .submitLabel(.done)
                            .onSubmit {
                                titleFocused = false
                                store.send(.titleCommitted)
                            }
                        if !titleFocused {
                            Image(systemName: "pencil")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color(.tertiaryLabel))
                        }
                    }
                    Rectangle()
                        .fill(titleFocused ? Brand.pink : Color.clear)
                        .frame(height: 2)
                        .animation(.easeInOut(duration: 0.2), value: titleFocused)
                }
                Spacer()
                if titleFocused && store.isSaved {
                    Button("완료") {
                        titleFocused = false
                        store.send(.titleCommitted)
                    }
                    .font(Typography.caption.weight(.semibold))
                    .foregroundStyle(Brand.pink)
                    .padding(.top, 20)
                }
            }

            if let note = store.placeCountNote {
                Divider()
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.orange)
                    Text(note)
                        .font(Typography.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // Metadata row
            if !store.course.courseReason.isEmpty || store.course.outfitSuggestion != nil {
                Divider()
                VStack(alignment: .leading, spacing: 10) {
                    if !store.course.courseReason.isEmpty {
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(Typography.caption)
                                .foregroundStyle(Brand.pink)
                                .frame(width: 14)
                                .padding(.top, 1)
                            Text(store.course.courseReason)
                                .font(Typography.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    if let outfit = store.course.outfitSuggestion, !outfit.isEmpty {
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "tshirt")
                                .font(Typography.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 14)
                                .padding(.top, 1)
                            Text(outfit)
                                .font(Typography.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
        .padding(Spacing.md)
        .cardStyle()
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        let visited = store.visitedOrders.count
        let total = store.course.places.count
        let progress = total > 0 ? Double(visited) / Double(total) : 0

        return VStack(spacing: 8) {
            HStack {
                Text("진행 중")
                    .font(Typography.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(visited)/\(total) 완료")
                    .font(Typography.caption.weight(.bold))
                    .foregroundStyle(Brand.pink)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(Color(.systemFill)).frame(height: 6)
                    RoundedRectangle(cornerRadius: 4).fill(Brand.pink)
                        .frame(width: geo.size.width * progress, height: 6)
                        .animation(.spring(response: 0.4), value: progress)
                }
            }
            .frame(height: 6)
        }
        .padding(Spacing.md)
        .cardStyle()
    }

    // MARK: - Timeline

    private var timelinePlaces: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("코스")
                    .font(Typography.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                if !store.isPlaying {
                    if isReordering {
                        HStack(spacing: 12) {
                            Button("취소") {
                                Haptics.impact(.light)
                                store.send(.resetPlaces(placesBeforeReorder))
                                withAnimation { isReordering = false }
                            }
                            .font(Typography.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            Button("완료") {
                                Haptics.impact(.light)
                                withAnimation { isReordering = false }
                            }
                            .font(Typography.caption.weight(.semibold))
                            .foregroundStyle(Brand.pink)
                        }
                    } else {
                        HStack(spacing: 10) {
                            Label("탭하면 지도 이동", systemImage: "mappin.and.ellipse")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.secondary)
                            Button("순서 편집") {
                                Haptics.impact(.light)
                                placesBeforeReorder = store.course.places
                                withAnimation { isReordering = true }
                            }
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Brand.pink)
                        }
                    }
                }
            }
            .padding(.leading, 4)
            .padding(.bottom, 8)

            if isReordering {
                reorderList
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(store.course.places.enumerated()), id: \.element.order) { index, place in
                        timelineRow(place: place, index: index)
                            .padding(Spacing.md)
                            .cardStyle()

                        if index < store.course.places.count - 1 {
                            HStack(spacing: 0) {
                                Spacer().frame(width: Spacing.md + 16)
                                Rectangle()
                                    .fill(Color(.separator).opacity(0.6))
                                    .frame(width: 2, height: 14)
                                Spacer()
                            }
                        }
                    }
                }
            }
        }
    }

    private var reorderList: some View {
        List {
            ForEach(Array(store.course.places.enumerated()), id: \.element.order) { index, place in
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(placeColors[index % placeColors.count])
                            .frame(width: 28, height: 28)
                        Text("\(place.order)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(place.placeName ?? place.keyword)
                            .font(Typography.body.weight(.semibold))
                        Text(place.category)
                            .font(Typography.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "line.3.horizontal")
                        .foregroundStyle(.secondary)
                }
                .listRowBackground(Color(.systemBackground))
            }
            .onMove { source, destination in
                Haptics.impact(.light)
                store.send(.reorderPlaces(source, destination))
            }
            .onDelete { offsets in
                Haptics.notification(.warning)
                store.send(.removePlace(offsets))
            }
        }
        .listStyle(.plain)
        .frame(height: CGFloat(store.course.places.count) * 60)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8)
        .environment(\.editMode, .constant(.active))
        .environment(\.locale, Locale(identifier: "ko_KR"))
    }

    private func timelineRow(place: CoursePlace, index: Int) -> some View {
        let color = placeColors[index % placeColors.count]
        let isVisited = store.visitedOrders.contains(place.order)

        return HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(isVisited ? Color(.systemFill) : color)
                    .frame(width: 32, height: 32)
                if isVisited {
                    Image(systemName: "checkmark")
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(color)
                } else {
                    Text("\(place.order)")
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                }
            }

            // Place info
            VStack(alignment: .leading, spacing: 5) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 4) {
                                Text(place.placeName ?? place.keyword)
                                    .font(Typography.body.weight(.semibold))
                                    .foregroundStyle(isVisited ? .secondary : .primary)
                                    .lineLimit(1)
                                if !store.isPlaying {
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.system(size: 13))
                                        .foregroundStyle(color.opacity(isVisited ? 0.3 : 0.7))
                                }
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                if let category = displayCategory(for: place) {
                                    Text(category)
                                        .font(Typography.caption2.weight(.medium))
                                        .foregroundStyle(isVisited ? .secondary : color)
                                        .lineLimit(1)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background((isVisited ? Color.secondary : color).opacity(0.1))
                                        .clipShape(Capsule())
                                }

                                if let address = displayAddress(for: place) {
                                    Label(address, systemImage: "mappin.and.ellipse")
                                        .font(Typography.caption2)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                        }

                        Spacer(minLength: 8)

                        if store.isPlaying {
                            ZStack {
                                Circle()
                                    .stroke(isVisited ? color : Color(.systemFill), lineWidth: 2)
                                    .frame(width: 30, height: 30)
                                if isVisited {
                                    Circle().fill(color).frame(width: 30, height: 30)
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            }
                            .animation(.spring(response: 0.3), value: isVisited)
                            .onTapGesture { Haptics.impact(.rigid); store.send(.placeVisited(place.order)) }
                        } else {
                            actionButtons(for: place)
                        }
                    }

                    if !isVisited {
                        Text(place.reason)
                            .font(Typography.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)

                        if let placeType = displayPlaceType(for: place) {
                            Label(placeType, systemImage: "tag.fill")
                                .font(Typography.caption2)
                                .foregroundStyle(Brand.pink)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .opacity(isVisited && store.isPlaying ? 0.55 : 1)
            .animation(.easeInOut(duration: 0.2), value: isVisited)
        }
        .scaleEffect(tappedPlaceOrder == place.order ? 0.97 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: tappedPlaceOrder)
        .contentShape(Rectangle())
        .gesture(TapGesture().onEnded {
            Haptics.selection()
            tappedPlaceOrder = place.order
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { tappedPlaceOrder = nil }
            focusMap(on: place)
        })
    }

    private func actionButtons(for place: CoursePlace) -> some View {
        HStack(spacing: 6) {
            let isBookmarked = store.bookmarkedKeywords.contains(place.keyword)
            Button {
                Haptics.impact(.light)
                store.send(.bookmarkPlace(place))
            } label: {
                VStack(spacing: 2) {
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 14))
                    Text("찜").font(.system(size: 10, weight: .medium))
                }
                .foregroundStyle(isBookmarked ? Brand.pink : .secondary)
                .padding(7)
                .background(isBookmarked ? Brand.softPink : Color(.tertiarySystemFill))
                .clipShape(RoundedRectangle(cornerRadius: 9))
            }

            Button { openKakaoMap(place: place) } label: {
                VStack(spacing: 2) {
                    Image(systemName: "info.circle.fill").font(.system(size: 14))
                    Text("상세").font(.system(size: 10, weight: .medium))
                }
                .foregroundStyle(Brand.pink)
                .padding(7)
                .background(Brand.softPink)
                .clipShape(RoundedRectangle(cornerRadius: 9))
            }
        }
    }

    // MARK: - Rating Card

    private func ratingCard(label: String, rating: Int, review: String?) -> some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.yellow.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: "star.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.yellow)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= rating ? "star.fill" : "star")
                            .font(.system(size: 12))
                            .foregroundStyle(star <= rating ? .yellow : Color(.systemFill))
                    }
                }
                if let review, !review.isEmpty {
                    Text(review).font(Typography.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(Spacing.md)
        .cardStyle()
    }

    // MARK: - Candidates Accordion

    private var candidatesAccordion: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.35)) { showCandidates.toggle() }
            } label: {
                HStack {
                    Text("다른 후보 장소")
                        .font(Typography.caption.weight(.semibold))
                        .foregroundStyle(.primary)
                    Spacer()
                    Text("\(store.course.candidates.count)곳")
                        .font(Typography.caption2)
                        .foregroundStyle(.secondary)
                    Image(systemName: showCandidates ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(Spacing.md)
            }
            .buttonStyle(.plain)

            if showCandidates {
                Divider().padding(.horizontal, Spacing.md)
                VStack(spacing: 0) {
                    ForEach(Array(store.course.candidates.enumerated()), id: \.element.order) { index, place in
                        candidateRow(place: place, index: index, isLast: index == store.course.candidates.count - 1)
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.md)
            }
        }
        .cardStyle()
    }

    @ViewBuilder
    private func candidateRow(place: CoursePlace, index: Int, isLast: Bool) -> some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.tertiarySystemFill))
                    .frame(width: 30, height: 30)
                Text("\(index + 1)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(place.placeName ?? place.keyword)
                    .font(Typography.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(place.reason)
                    .font(Typography.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 6) {
                Button { openKakaoMap(place: place) } label: {
                    VStack(spacing: 2) {
                        Image(systemName: "info.circle.fill").font(.system(size: 13))
                        Text("상세").font(.system(size: 9, weight: .medium))
                    }
                    .foregroundStyle(Brand.pink)
                    .padding(6)
                    .background(Brand.softPink)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                Button {
                    Haptics.impact(.medium)
                    store.send(.addCandidate(place))
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: "plus").font(.system(size: 13, weight: .semibold))
                        Text("추가").font(.system(size: 9, weight: .medium))
                    }
                    .foregroundStyle(.white)
                    .padding(6)
                    .background(Brand.pink)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(.vertical, 10)
        if !isLast { Divider() }
    }

    // MARK: - Floating Buttons

    private var startButton: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                utilityButton(icon: "clock.fill", label: "출발 시각") { store.send(.departureTapped) }
                utilityButton(icon: "checklist", label: "체크리스트") { store.send(.checklistTapped) }
            }
            HStack(spacing: Spacing.md) {
                Button { Haptics.impact(.medium); store.send(.likeTapped) } label: {
                    Image(systemName: store.course.isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 22))
                        .foregroundStyle(store.course.isLiked ? Brand.pink : Color(.secondaryLabel))
                        .frame(width: 48, height: 48)
                        .background(Color(.systemFill))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                Button { Haptics.impact(.rigid); store.send(.startPlayTapped) } label: {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "play.fill").font(.system(size: 14, weight: .semibold))
                        Text("데이트 시작").font(Typography.body.weight(.bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Brand.pink)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Brand.pink.opacity(0.3), radius: 10, x: 0, y: 4)
                }
                Button { store.send(.deleteTapped) } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 20))
                        .foregroundStyle(Color(.secondaryLabel))
                        .frame(width: 48, height: 48)
                        .background(Color(.systemFill))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
        .background(.regularMaterial)
    }

    private var saveButton: some View {
        Button {
            guard !store.course.title.trimmingCharacters(in: .whitespaces).isEmpty else {
                Haptics.notification(.warning)
                titleFocused = true
                return
            }
            titleFocused = false
            Haptics.notification(.success)
            store.send(.saveTapped)
        } label: {
            Text("저장하기")
                .font(Typography.body.weight(.bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(Brand.pink)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Brand.pink.opacity(0.3), radius: 10, x: 0, y: 4)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
        .background(.regularMaterial)
    }

    // MARK: - Completion Sheet

    private var completionSheet: some View {
        NavigationStack {
            VStack(spacing: Spacing.xl) {
                VStack(spacing: Spacing.sm) {
                    Text("🎉").font(.system(size: 56))
                    Text("데이트 완료!").font(.system(size: 24, weight: .bold))
                    Text("오늘 데이트는 어떠셨나요?")
                        .font(Typography.body).foregroundStyle(.secondary)
                }
                .padding(.top, Spacing.xl)

                VStack(spacing: Spacing.md) {
                    HStack(spacing: 12) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= store.completionRating ? "star.fill" : "star")
                                .font(.system(size: 36))
                                .foregroundStyle(star <= store.completionRating ? .yellow : Color(.systemFill))
                                .scaleEffect(star <= store.completionRating ? 1.1 : 1.0)
                                .animation(.spring(response: 0.2), value: store.completionRating)
                                .onTapGesture { store.send(.binding(.set(\.completionRating, star))) }
                        }
                    }
                    TextField("한 줄 후기 (선택)", text: $store.completionReview)
                        .font(Typography.body)
                        .padding(Spacing.md)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, Spacing.md)
                }
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("건너뛰기") { store.send(.skipReviewTapped) }.foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") { store.send(.saveReviewTapped) }
                        .font(Typography.body.weight(.semibold))
                        .disabled(store.completionRating == 0)
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Map Helpers

    private func focusMap(on place: CoursePlace) {
        guard let lat = place.latitude, let lon = place.longitude else { return }
        withAnimation(.easeInOut(duration: 0.5)) {
            mapCameraPosition = .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                span: MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003)
            ))
        }
    }

    private func mapRegion(for coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        let lats = coordinates.map { $0.latitude }
        let lons = coordinates.map { $0.longitude }
        guard let minLat = lats.min(), let maxLat = lats.max(),
              let minLon = lons.min(), let maxLon = lons.max() else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.6, 0.008),
            longitudeDelta: max((maxLon - minLon) * 1.6, 0.008)
        )
        return MKCoordinateRegion(center: center, span: span)
    }

    // MARK: - Kakao Map

    @MainActor
    private func renderShareCard() async -> UIImage? {
        let size = CGSize(width: 390, height: 520)
        let hosting = UIHostingController(rootView: CourseShareCard(course: store.course).ignoresSafeArea())
        hosting.view.frame = CGRect(x: -size.width * 2, y: 0, width: size.width, height: size.height)
        hosting.view.backgroundColor = .clear
        hosting.additionalSafeAreaInsets = .zero

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return nil }
        window.addSubview(hosting.view)
        hosting.view.layoutIfNeeded()

        // SwiftUI 첫 렌더링 완료 대기
        try? await Task.sleep(nanoseconds: 150_000_000)

        let format = UIGraphicsImageRendererFormat()
        format.scale = 3.0
        let image = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            hosting.view.drawHierarchy(in: hosting.view.bounds, afterScreenUpdates: true)
        }
        hosting.view.removeFromSuperview()
        return image
    }

    private func utilityButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(Brand.pink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Brand.softPink)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private func openKakaoMap(place: CoursePlace) {
        let placeName = place.placeName ?? place.keyword

        if let urlString = place.kakaoPlaceURL,
           let url = URL(string: urlString) {
            UIApplication.shared.open(url)
            return
        }

        // 1순위: 카카오 장소 ID로 정확한 장소 페이지 오픈
        if let placeId = place.kakaoPlaceId {
            let appURLString = "kakaomap://place?id=\(placeId)"
            if let appURL = URL(string: appURLString), UIApplication.shared.canOpenURL(appURL) {
                UIApplication.shared.open(appURL)
                return
            }
            if let webURL = URL(string: "https://place.map.kakao.com/\(placeId)") {
                UIApplication.shared.open(webURL)
                return
            }
        }

        // 2순위: 좌표 + 이름으로 검색 (placeId 없는 경우)
        if let lat = place.latitude, let lon = place.longitude,
           let encoded = placeName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let appURL = URL(string: "kakaomap://search?q=\(encoded)&p=\(lat),\(lon)"),
           UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL)
            return
        }

        // 3순위: 웹 fallback
        guard let encoded = placeName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let webURL = URL(string: "https://map.kakao.com/link/search/\(encoded)") else { return }
        UIApplication.shared.open(webURL)
    }

    private func displayCategory(for place: CoursePlace) -> String? {
        let category = place.category
            .split(separator: ">")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .last ?? place.category.trimmingCharacters(in: .whitespacesAndNewlines)
        return category.isEmpty ? nil : category
    }

    private func displayPlaceType(for place: CoursePlace) -> String? {
        if let specificType = specificPlaceType(for: place) {
            return specificType
        }
        return displayCategory(for: place)
    }

    private func specificPlaceType(for place: CoursePlace) -> String? {
        let text = [
            place.placeName,
            place.keyword,
            place.category,
            place.reason,
        ]
        .compactMap { $0 }
        .joined(separator: " ")
        .lowercased()

        let aliases: [(type: String, keywords: [String])] = [
            ("훠궈 전문점", ["훠궈", "하이디라오", "haidilao", "hot pot", "hotpot"]),
            ("마라탕 전문점", ["마라탕"]),
            ("마라샹궈 전문점", ["마라샹궈"]),
            ("양꼬치 전문점", ["양꼬치"]),
            ("샤브샤브 전문점", ["샤브샤브"]),
            ("스시/초밥", ["초밥", "스시", "sushi"]),
            ("회/사시미", ["사시미", "회"]),
            ("오마카세", ["오마카세"]),
            ("라멘", ["라멘", "라면"]),
            ("우동", ["우동"]),
            ("돈카츠", ["돈카츠", "돈까스"]),
            ("이자카야", ["이자카야"]),
            ("파스타", ["파스타"]),
            ("피자", ["피자"]),
            ("스테이크", ["스테이크"]),
            ("와인바", ["와인바", "와인 바"]),
            ("고기구이", ["삼겹살", "고깃집", "고기집", "구이", "갈비"]),
            ("곱창/막창", ["곱창", "막창"]),
            ("족발/보쌈", ["족발", "보쌈"]),
            ("닭갈비", ["닭갈비"]),
            ("치킨", ["치킨"]),
            ("버거", ["버거", "햄버거"]),
            ("타코", ["타코"]),
            ("쌀국수", ["쌀국수"]),
            ("딤섬", ["딤섬"]),
            ("중식", ["짜장", "자장", "짬뽕"]),
            ("떡볶이", ["떡볶이"]),
            ("브런치 카페", ["브런치"]),
            ("베이커리", ["베이커리", "빵집"]),
            ("디저트 카페", ["디저트", "케이크", "빙수", "도넛"]),
        ]

        return aliases.first { alias in
            alias.keywords.contains { text.contains($0) }
        }?.type
    }

    private func displayAddress(for place: CoursePlace) -> String? {
        guard let address = place.address?.trimmingCharacters(in: .whitespacesAndNewlines),
              !address.isEmpty else {
            return nil
        }
        return address
    }
}

// MARK: - Course Share Card

private struct CourseShareCard: View {
    let course: Course

    private var dateText: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M월 d일 (E)"
        return f.string(from: course.date)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.88, green: 0.13, blue: 0.33),
                    Color(red: 0.97, green: 0.33, blue: 0.48),
                    Color(red: 1.0, green: 0.56, blue: 0.36).opacity(0.85)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(.white.opacity(0.07))
                .frame(width: 320)
                .blur(radius: 60)
                .offset(x: -100, y: -280)

            Circle()
                .fill(.white.opacity(0.05))
                .frame(width: 220)
                .blur(radius: 40)
                .offset(x: 160, y: 240)

            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("ForP")
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        Text("AI 데이트 코스")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.65))
                            .tracking(1.5)
                    }
                    Spacer()
                    Text(dateText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.white.opacity(0.18))
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 32)
                .padding(.top, 48)

                Spacer()

                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(course.title)
                            .font(.system(size: 30, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(2)

                        if let rating = course.rating {
                            HStack(spacing: 3) {
                                ForEach(1...5, id: \.self) { i in
                                    Image(systemName: i <= rating ? "star.fill" : "star")
                                        .font(.system(size: 13))
                                        .foregroundStyle(i <= rating ? Color.yellow : .white.opacity(0.35))
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(Array(course.places.prefix(5).enumerated()), id: \.offset) { index, place in
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(.white.opacity(0.22))
                                        .frame(width: 28, height: 28)
                                    Text("\(place.order)")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white)
                                }
                                Text(place.placeName ?? place.keyword)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                Spacer()
                                Text(place.category)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.75))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(.white.opacity(0.18))
                                    .clipShape(Capsule())
                            }
                        }
                        if course.places.count > 5 {
                            Text("외 \(course.places.count - 5)곳 더")
                                .font(.system(size: 11))
                                .foregroundStyle(.white.opacity(0.55))
                                .padding(.leading, 40)
                        }
                    }
                }
                .padding(.horizontal, 32)

                Spacer()

                HStack {
                    Text("ForP로 만든 데이트 코스")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.55))
                    Spacer()
                    Image(systemName: "heart.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.45))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 44)
            }
        }
        .frame(width: 390, height: 520)
    }
}
