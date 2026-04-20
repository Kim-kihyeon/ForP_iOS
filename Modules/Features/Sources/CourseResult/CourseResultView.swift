import SwiftUI
import ComposableArchitecture
import CoreSharedUI
import Domain
import MapKit

public struct CourseResultView: View {
    @Bindable var store: StoreOf<CourseResultFeature>
    @FocusState private var titleFocused: Bool
    @Environment(\.colorScheme) private var colorScheme
    @State private var mapCameraPosition: MapCameraPosition = .automatic
    @State private var showCandidates = false
    @State private var tappedPlaceOrder: Int? = nil

    private var coordinatePlaces: [(CoursePlace, CLLocationCoordinate2D)] {
        store.course.places.compactMap { place in
            guard let lat = place.latitude, let lon = place.longitude else { return nil }
            return (place, CLLocationCoordinate2D(latitude: lat, longitude: lon))
        }
    }

    private var placeColors: [Color] {
        colorScheme == .dark
            ? [Brand.pink, Color(red: 0.3, green: 0.5, blue: 0.95), Color(red: 0.5, green: 0.3, blue: 0.95), Color(red: 0.1, green: 0.65, blue: 0.55), Color(red: 0.85, green: 0.45, blue: 0.1), Color(red: 0.85, green: 0.25, blue: 0.25)]
            : [Brand.pink, Color(red: 0.4, green: 0.6, blue: 1.0), Color(red: 0.6, green: 0.4, blue: 1.0), Color(red: 0.2, green: 0.78, blue: 0.65), Color(red: 1.0, green: 0.6, blue: 0.2), Color(red: 1.0, green: 0.4, blue: 0.4)]
    }

    public init(store: StoreOf<CourseResultFeature>) {
        self.store = store
    }

    public var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    heroMap
                    mainContent
                }
                .padding(.bottom, 32)
            }

            if store.isSaving || store.isDeleting {
                LoadingView()
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !store.isSaved {
                saveButton
            } else if !store.isPlaying {
                startButton
            }
        }
        .navigationTitle(store.course.title)
        .navigationBarTitleDisplayMode(.inline)
        .tint(Brand.pink)
        .toolbarBackground(Brand.softPink, for: .navigationBar)
        .onDisappear { store.send(.viewDisappeared) }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if store.isPlaying {
                    Button("종료") { store.send(.stopPlayTapped) }
                        .foregroundStyle(Brand.pink)
                }
            }
        }
        .alert($store.scope(state: \.alert, action: \.alert))
        .sheet(isPresented: $store.showCompletion) {
            completionSheet
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
            if store.isPlaying { progressBar }
            timelinePlaces
            if let rating = store.course.rating, !store.isPlaying {
                ratingCard(rating: rating, review: store.course.review)
            }
            if !store.candidates.isEmpty, !store.isPlaying {
                candidatesAccordion
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, 16)
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
                    TextField("코스 제목", text: $store.course.title)
                        .font(.system(size: 22, weight: .bold))
                        .focused($titleFocused)
                        .submitLabel(.done)
                        .onSubmit {
                            titleFocused = false
                            store.send(.titleCommitted)
                        }
                    Rectangle()
                        .fill(titleFocused ? Brand.pink : Color(.separator))
                        .frame(height: titleFocused ? 2 : 1)
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

            // Metadata row
            if !store.courseReason.isEmpty || store.course.outfitSuggestion != nil {
                Divider()
                VStack(alignment: .leading, spacing: 10) {
                    if !store.courseReason.isEmpty {
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(Typography.caption)
                                .foregroundStyle(Brand.pink)
                                .frame(width: 14)
                                .padding(.top, 1)
                            Text(store.courseReason)
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
                    Label("탭하면 지도 이동", systemImage: "mappin.and.ellipse")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.leading, 4)
            .padding(.bottom, 8)

            VStack(spacing: 0) {
                ForEach(Array(store.course.places.enumerated()), id: \.element.order) { index, place in
                    timelineRow(place: place, index: index, isLast: index == store.course.places.count - 1)
                }
            }
            .padding(Spacing.md)
            .cardStyle()
        }
    }

    private func timelineRow(place: CoursePlace, index: Int, isLast: Bool) -> some View {
        let color = placeColors[index % placeColors.count]
        let isVisited = store.visitedOrders.contains(place.order)

        return HStack(alignment: .top, spacing: 14) {
            // Timeline indicator
            VStack(spacing: 0) {
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
                if !isLast {
                    Rectangle()
                        .fill(Color(.separator))
                        .frame(width: 1.5)
                        .frame(minHeight: 24)
                        .padding(.vertical, 4)
                }
            }

            // Place info
            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 4) {
                            Text(place.placeName ?? place.keyword)
                                .font(Typography.body.weight(.semibold))
                                .foregroundStyle(isVisited ? .secondary : .primary)
                            if !store.isPlaying {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 13))
                                    .foregroundStyle(color.opacity(isVisited ? 0.3 : 0.7))
                            }
                        }

                        HStack(spacing: 6) {
                            Text(place.category)
                                .font(Typography.caption2)
                                .foregroundStyle(isVisited ? .secondary : color)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background((isVisited ? Color.secondary : color).opacity(0.1))
                                .clipShape(Capsule())

                            if let addr = place.address {
                                Text(addr)
                                    .font(Typography.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }

                        if !isVisited {
                            Text(place.reason)
                                .font(Typography.caption)
                                .foregroundStyle(.secondary)
                                .padding(.top, 1)

                            if let menu = place.menu, !menu.isEmpty {
                                Label(menu, systemImage: "fork.knife")
                                    .font(Typography.caption2)
                                    .foregroundStyle(Brand.pink)
                            }
                        }
                    }

                    Spacer()

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
                        .onTapGesture { store.send(.placeVisited(place.order)) }
                    } else {
                        Button { openKakaoMap(place: place) } label: {
                            VStack(spacing: 2) {
                                Image(systemName: "map.fill").font(.system(size: 14))
                                Text("지도").font(.system(size: 10, weight: .medium))
                            }
                            .foregroundStyle(Brand.pink)
                            .padding(7)
                            .background(Brand.softPink)
                            .clipShape(RoundedRectangle(cornerRadius: 9))
                        }
                    }
                }
            }
            .padding(.bottom, isLast ? 0 : 16)
            .opacity(isVisited && store.isPlaying ? 0.55 : 1)
            .animation(.easeInOut(duration: 0.2), value: isVisited)
        }
        .scaleEffect(tappedPlaceOrder == place.order ? 0.97 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: tappedPlaceOrder)
        .onTapGesture {
            tappedPlaceOrder = place.order
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { tappedPlaceOrder = nil }
            focusMap(on: place)
        }
    }

    // MARK: - Rating Card

    private func ratingCard(rating: Int, review: String?) -> some View {
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
                    Text("\(store.candidates.count)곳")
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
                    ForEach(Array(store.candidates.enumerated()), id: \.element.order) { index, place in
                        candidateRow(place: place, index: index, isLast: index == store.candidates.count - 1)
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
            Button { openKakaoMap(place: place) } label: {
                VStack(spacing: 2) {
                    Image(systemName: "map.fill").font(.system(size: 13))
                    Text("지도").font(.system(size: 9, weight: .medium))
                }
                .foregroundStyle(Brand.pink)
                .padding(6)
                .background(Brand.softPink)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.vertical, 10)
        if !isLast { Divider() }
    }

    // MARK: - Floating Buttons

    private var startButton: some View {
        HStack(spacing: Spacing.md) {
            Button { store.send(.likeTapped) } label: {
                Image(systemName: store.course.isLiked ? "heart.fill" : "heart")
                    .font(.system(size: 22))
                    .foregroundStyle(store.course.isLiked ? Brand.pink : Color(.secondaryLabel))
                    .frame(width: 48, height: 48)
                    .background(Color(.systemFill))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            Button { store.send(.startPlayTapped) } label: {
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
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
        .background(.regularMaterial)
    }

    private var saveButton: some View {
        Button {
            titleFocused = false
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
        let center = CLLocationCoordinate2D(
            latitude: (lats.min()! + lats.max()!) / 2,
            longitude: (lons.min()! + lons.max()!) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max((lats.max()! - lats.min()!) * 1.6, 0.008),
            longitudeDelta: max((lons.max()! - lons.min()!) * 1.6, 0.008)
        )
        return MKCoordinateRegion(center: center, span: span)
    }

    // MARK: - Kakao Map

    private func openKakaoMap(place: CoursePlace) {
        let placeName = place.placeName ?? place.keyword
        guard let encoded = placeName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }

        let appURLString: String
        if let lat = place.latitude, let lon = place.longitude {
            appURLString = "kakaomap://search?q=\(encoded)&p=\(lat),\(lon)"
        } else {
            appURLString = "kakaomap://search?q=\(encoded)"
        }

        guard let appURL = URL(string: appURLString) else { return }
        UIApplication.shared.open(appURL) { success in
            guard !success else { return }
            guard let encoded2 = placeName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
                  let webURL = URL(string: "https://map.kakao.com/link/search/\(encoded2)") else { return }
            UIApplication.shared.open(webURL)
        }
    }
}
