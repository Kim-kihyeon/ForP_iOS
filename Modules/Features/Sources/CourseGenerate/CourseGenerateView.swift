import SwiftUI
import ComposableArchitecture
import CoreSharedUI
import Domain

public struct CourseGenerateView: View {
    @Bindable var store: StoreOf<CourseGenerateFeature>
    @State private var showAllThemes = false
    @State private var showCancelGenerationConfirm = false
    @FocusState private var locationFocused: Bool

    public init(store: StoreOf<CourseGenerateFeature>) {
        self.store = store
    }

    private var canGenerate: Bool {
        !store.selectedLocations.isEmpty
    }

    private var loadingMessages: [String] {
        if store.isRandom {
            return [
                "취향은 잠깐 내려놓고 새 조합을 찾고 있어요",
                "예상 밖이어도 말 되는 동선을 맞춰보고 있어요",
                "식사·카페·활동이 한쪽으로 쏠리지 않게 보고 있어요",
                "너무 뻔한 후보는 살짝 빼는 중이에요",
                "오늘 바로 가도 어색하지 않은 코스로 다듬고 있어요",
            ]
        }

        let themes = store.selectedThemes
        if themes.contains(where: { $0.contains("맛집") || $0.contains("음식") }) {
            return [
                "맛있는 곳만 몰아넣지 않게 균형을 보고 있어요",
                "식사 후 쉬어갈 카페나 가벼운 장소도 같이 맞춰봐요",
                "기준점에서 너무 먼 맛집은 덜어내고 있어요",
                "후보 장소까지 넉넉하게 검증하는 중이에요",
                "배부른데 또 식당 가는 코스는 피하고 있어요",
            ]
        }
        if themes.contains(where: { $0.contains("카페") || $0.contains("디저트") || $0.contains("감성") }) {
            return [
                "카페만 이어지지 않게 코스 흐름을 보고 있어요",
                "대화하기 좋은 곳과 움직일 곳을 같이 맞춰봐요",
                "체인보다 분위기 있는 후보를 먼저 살피는 중이에요",
                "사진보다 실제 동선이 괜찮은지 확인하고 있어요",
                "달달함 과다 복용은 살짝 조절하고 있어요",
            ]
        }
        if themes.contains(where: { $0.contains("술") || $0.contains("밤") || $0.contains("야경") }) {
            return [
                "저녁 흐름에 맞게 식사와 마무리 장소를 맞춰요",
                "한 잔하기 전후 동선이 어색하지 않은지 보고 있어요",
                "너무 멀리 이동하는 밤 코스는 빼고 있어요",
                "분위기와 안전한 이동 거리를 같이 확인해요",
                "끝나고 집 가기 싫어지는 정도까지만 다듬고 있어요",
            ]
        }
        if !store.memo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return [
                "요청사항을 먼저 반영하고 있어요",
                "싫다고 한 조건은 조용히 피하는 중이에요",
                "원하는 분위기와 실제 장소가 맞는지 보고 있어요",
                "후보까지 넉넉하게 비교하고 있어요",
                "말한 건 최대한 기억하는 척이 아니라 진짜 반영 중이에요",
            ]
        }
        return [
            "식사·카페·활동이 자연스럽게 섞이는지 보고 있어요",
            "기준점에서 너무 먼 곳은 덜어내고 있어요",
            "너무 뻔한 곳은 살짝 빼고 있어요",
            "괜찮은 후보만 남겨보고 있어요",
            "마지막 조합을 다듬고 있어요",
        ]
    }

    private var loadingSubtitle: String {
        let locations = store.selectedLocations.map { $0.placeName ?? $0.keyword }.joined(separator: ", ")
        if store.isRandom {
            return "\(locations) 근처에서 뜻밖이지만 말 되는 코스를 찾는 중"
        }
        if !store.selectedThemes.isEmpty {
            return "\(store.selectedThemes.joined(separator: "·")) 분위기에 맞춰 고르고 있어요"
        }
        if !store.memo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "요청사항과 실제 장소 정보를 같이 맞춰보고 있어요"
        }
        return "\(locations) 근처에서 데이트 흐름을 맞추고 있어요"
    }

    public var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        locationSection
                        randomSection
                        if store.isRandom {
                            randomActiveCard
                        } else {
                            themeSection
                                .transition(.opacity.combined(with: .scale(scale: 0.97, anchor: .top)))
                            memoSection
                                .transition(.opacity.combined(with: .scale(scale: 0.97, anchor: .top)))
                            if !store.wishlistPlaces.isEmpty {
                                wishlistSection
                                    .transition(.opacity.combined(with: .scale(scale: 0.97, anchor: .top)))
                            }
                        }
                        placeCountSection
                        dateSection
                    }
                    .animation(.easeInOut(duration: 0.22), value: store.isRandom)
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.md)
                    .padding(.bottom, Spacing.sm)
                }

                generateButtonBar
            }

            if store.isGenerating {
                CourseLoadingView(
                    messages: loadingMessages,
                    subtitle: loadingSubtitle
                )
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        Button {
                            Haptics.impact(.light)
                            showCancelGenerationConfirm = true
                        } label: {
                            Text("취소")
                                .font(Typography.body.weight(.medium))
                                .foregroundStyle(.white.opacity(0.85))
                                .padding(.horizontal, Spacing.xl)
                                .padding(.vertical, Spacing.sm)
                                .background(Color.white.opacity(0.18))
                                .clipShape(Capsule())
                        }
                        .padding(.bottom, Spacing.xl)
                    }
            }
        }
        .hideKeyboardOnTap()
        .swipeBackDisabled(store.isGenerating)
        .onAppear { store.send(.onAppear) }
        .navigationTitle("코스 만들기")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(store.isGenerating)
        .toolbar(store.isGenerating ? .hidden : .visible, for: .navigationBar)
        .tint(Brand.pink)
        .toolbarBackground(Brand.softPink, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .alert("코스 생성을 중지할까요?", isPresented: $showCancelGenerationConfirm) {
            Button("중지", role: .destructive) {
                store.send(.cancelGenerationTapped)
            }
            Button("계속 생성", role: .cancel) {}
        } message: {
            Text("지금 중지하면 다시 생성해야 해요.")
        }
        .alert("코스 생성 실패", isPresented: Binding(
            get: { store.errorMessage != nil },
            set: { _ in }
        )) {
            Button("다시 시도") { store.send(.retryTapped) }
            Button("취소", role: .cancel) { store.send(.cancelGenerationTapped) }
        } message: {
            Text(store.errorMessage ?? "")
        }
    }

    // MARK: - Location

    private var locationSection: some View {
        VStack(spacing: 0) {
            FormCard {
                HStack(alignment: .top, spacing: Spacing.md) {
                    iconBadge("location.fill", color: Brand.pink)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("어디서?")
                                .font(Typography.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Spacer()
                            if !store.selectedLocations.isEmpty {
                                Text("\(store.selectedLocations.count)/3")
                                    .font(Typography.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if !store.selectedLocations.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(Array(store.selectedLocations.enumerated()), id: \.offset) { index, place in
                                        locationChip(place.placeName ?? place.keyword, index: index)
                                    }
                                }
                            }
                        }

                        if store.selectedLocations.count < 3 {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 6) {
                                    TextField(
                                        store.selectedLocations.isEmpty ? "홍대, 강남, 사당역..." : "동네 추가 입력...",
                                        text: $store.locationQuery
                                    )
                                    .font(Typography.body.weight(.medium))
                                    .focused($locationFocused)
                                    if store.isSearchingLocation {
                                        ProgressView().scaleEffect(0.7)
                                    }
                                }
                                if store.selectedLocations.isEmpty {
                                    Text("정확한 코스를 위해 검색 결과에서 동네를 선택해주세요")
                                        .font(Typography.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }

            if !store.locationSuggestions.isEmpty {
                VStack(spacing: 0) {
                    ForEach(Array(store.locationSuggestions.enumerated()), id: \.offset) { index, place in
                        Button {
                            Haptics.selection()
                            store.send(.locationSuggestionSelected(place))
                            locationFocused = store.selectedLocations.count < 3
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Brand.pink)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(place.placeName ?? place.keyword)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                    if let addr = place.address, !addr.isEmpty {
                                        Text(addr)
                                            .font(.system(size: 11))
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                }
                                Spacer()
                            }
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, 10)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        if index < store.locationSuggestions.count - 1 {
                            Divider().padding(.leading, 44)
                        }
                    }
                }
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
                .padding(.top, 4)
            } else if shouldShowLocationNoResults {
                SearchNoResultsView(message: "가까운 역이나 동네 이름으로 다시 검색해보세요")
                    .padding(.top, 4)
            }
        }
    }

    private var shouldShowLocationNoResults: Bool {
        store.locationQuery.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2 &&
        !store.isSearchingLocation &&
        store.locationSuggestions.isEmpty &&
        store.selectedLocations.count < 3
    }

    private func locationChip(_ name: String, index: Int) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "mappin.fill")
                .font(.system(size: 9))
            Text(name)
                .font(.system(size: 12, weight: .semibold))
                .lineLimit(1)
            Button {
                Haptics.selection()
                store.send(.removeSelectedLocation(index))
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .padding(.leading, 2)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Brand.softPink)
        .foregroundStyle(Brand.pink)
        .clipShape(Capsule())
        .overlay { Capsule().stroke(Brand.pink.opacity(0.4), lineWidth: 1) }
    }

    // MARK: - Random

    private var randomSection: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(store.isRandom ? Brand.iconPurple.opacity(0.18) : Brand.iconPurple.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: store.isRandom ? "dice.fill" : "dice")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Brand.iconPurple)
                    .symbolEffect(.bounce, value: store.isRandom)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("완전 랜덤")
                    .font(Typography.caption2.weight(.semibold))
                    .foregroundStyle(store.isRandom ? Brand.iconPurple : .secondary)
                Text(store.isRandom ? "AI가 취향 무시하고 재량껏 코스를 짤게요" : "취향 설정 없이 AI가 알아서 골라줘요")
                    .font(.system(size: 11))
                    .foregroundStyle(store.isRandom ? Brand.iconPurple.opacity(0.75) : .secondary)
                    .animation(.none, value: store.isRandom)
            }
            Spacer()
            Toggle("", isOn: $store.isRandom)
                .labelsHidden()
                .tint(Brand.iconPurple)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            store.isRandom
                ? Brand.iconPurple.opacity(0.07)
                : Color(.systemBackground)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    store.isRandom ? Brand.iconPurple.opacity(0.35) : Color.clear,
                    lineWidth: 1.5
                )
        )
        .shadow(
            color: store.isRandom ? Brand.iconPurple.opacity(0.12) : .black.opacity(0.06),
            radius: 8, x: 0, y: 2
        )
        .animation(.easeInOut(duration: 0.2), value: store.isRandom)
    }

    private var randomActiveCard: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Brand.iconPurple.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Brand.iconPurple)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("AI가 전부 정할게요")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Brand.iconPurple)
                Text("테마·요청사항·찜 목록 없이 완전 새로운 코스")
                    .font(.system(size: 11))
                    .foregroundStyle(Brand.iconPurple.opacity(0.65))
            }
            Spacer()
        }
        .padding(Spacing.md)
        .background(Brand.iconPurple.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Brand.iconPurple.opacity(0.25), lineWidth: 1)
        )
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 0.97, anchor: .top)),
            removal: .opacity.combined(with: .scale(scale: 0.97, anchor: .top))
        ))
    }

    // MARK: - Date

    private var dateSection: some View {
        FormCard {
            HStack(spacing: Spacing.md) {
                iconBadge("calendar", color: Brand.iconBlue)
                Text("언제?")
                    .font(Typography.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                DatePicker("", selection: $store.date, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .environment(\.locale, Locale(identifier: "ko_KR"))
                    .fixedSize()
            }
            let daysFromNow = Calendar.current.dateComponents([.day], from: Date(), to: store.date).day ?? 0
            HStack(spacing: 4) {
                Image(systemName: daysFromNow >= 0 && daysFromNow <= 4 ? "cloud.sun.fill" : "thermometer.medium")
                    .font(.caption2)
                Text(daysFromNow >= 0 && daysFromNow <= 4 ? "실제 날씨 예보가 코스에 반영돼요" : "계절 기반으로 반영돼요")
                    .font(Typography.caption2)
            }
            .foregroundStyle(.secondary)
            .padding(.top, 4)
        }
    }

    // MARK: - Place Count

    private var placeCountSection: some View {
        FormCard {
            HStack(spacing: Spacing.md) {
                iconBadge("mappin.and.ellipse", color: Brand.pink)
                Text("몇 곳?")
                    .font(Typography.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                HStack(spacing: Spacing.lg) {
                    Button {
                        if store.placeCount > 1 {
                            store.send(.binding(.set(\.placeCount, store.placeCount - 1)))
                        }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(store.placeCount > 1 ? Brand.pink : Color(.tertiaryLabel))
                    }
                    Text("\(store.placeCount)")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .frame(minWidth: 24)
                    Button {
                        if store.placeCount < 5 {
                            store.send(.binding(.set(\.placeCount, store.placeCount + 1)))
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(store.placeCount < 5 ? Brand.pink : Color(.tertiaryLabel))
                    }
                }
            }
        }
    }

    // MARK: - Theme

    private let availableThemes = PreferenceOptions.themes

    private var themeSection: some View {
        FormCard {
            HStack(spacing: Spacing.md) {
                iconBadge("tag.fill", color: Brand.iconOrange)
                Text("테마")
                    .font(Typography.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                if !store.selectedThemes.isEmpty {
                    Spacer()
                    Button("초기화") {
                        store.send(.binding(.set(\.selectedThemes, [])))
                    }
                    .font(Typography.caption2)
                    .foregroundStyle(.secondary)
                }
            }
            let visibleThemes = showAllThemes ? availableThemes : Array(availableThemes.prefix(6))
            let columns = [GridItem(.adaptive(minimum: 78))]
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(visibleThemes) { option in
                    let selected = store.selectedThemes.contains(option.name)
                    Button {
                        Haptics.selection()
                        var themes = store.selectedThemes
                        if selected {
                            themes.removeAll { $0 == option.name }
                        } else {
                            themes.append(option.name)
                        }
                        store.send(.binding(.set(\.selectedThemes, themes)))
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: option.systemImage ?? "sparkles")
                                .font(.system(size: 16))
                            Text(option.name)
                                .font(.system(size: 11, weight: .medium))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(selected ? Brand.softPink : Color(.tertiarySystemFill))
                        .foregroundStyle(selected ? Brand.pink : .secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay {
                            if selected {
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Brand.pink.opacity(0.4), lineWidth: 1.5)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.leading, 0)
            if availableThemes.count > 6 {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showAllThemes.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(showAllThemes ? "접기" : "더 보기")
                        Image(systemName: showAllThemes ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .font(Typography.caption.weight(.semibold))
                    .foregroundStyle(Brand.pink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Wishlist

    private var wishlistSection: some View {
        FormCard {
            HStack(spacing: Spacing.md) {
                iconBadge("bookmark.fill", color: Brand.iconOrange)
                Text("가고 싶은 곳 참고하기")
                    .font(Typography.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(i < store.selectedWishlistIds.count ? Brand.pink : Color(.tertiarySystemFill))
                            .frame(width: 7, height: 7)
                            .animation(.spring(response: 0.25), value: store.selectedWishlistIds.count)
                    }
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(store.wishlistPlaces) { place in
                        let selected = store.selectedWishlistIds.contains(place.id)
                        let maxReached = store.selectedWishlistIds.count >= 3 && !selected
                        WishlistChip(
                            name: place.placeName ?? place.keyword,
                            selected: selected,
                            disabled: maxReached
                        ) {
                            Haptics.selection()
                            store.send(.toggleWishlistPlace(place.id))
                        } onDelete: {
                            Haptics.selection()
                            store.send(.toggleWishlistPlace(place.id))
                        }
                    }
                }
                .padding(.vertical, 2)
            }
            .padding(.leading, 44)

            if store.selectedWishlistIds.count >= 3 {
                    Text("최대 3개 선택됐어요. 변경하려면 선택을 해제해주세요.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            } else if !store.selectedWishlistIds.isEmpty && !store.selectedLocations.isEmpty {
                let locationStr = store.selectedLocations.map { $0.placeName ?? $0.keyword }.joined(separator: ", ")
                Text("'\(locationStr)' 지역이 아닌 경우 AI가 비슷한 유형으로 대체해요.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }
        }
    }

    // MARK: - Memo

    private var memoSection: some View {
        FormCard {
            HStack(alignment: .top, spacing: Spacing.md) {
                iconBadge("sparkles", color: Brand.iconOrange)
                VStack(alignment: .leading, spacing: 4) {
                    Text("요청사항")
                        .font(Typography.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                    ZStack(alignment: .topLeading) {
                        if store.memo.isEmpty {
                            Text("예: 술집은 빼줘, 비 와서 실내 위주로, 너무 비싼 곳은 싫어")
                                .font(Typography.body)
                                .foregroundStyle(Color(.placeholderText))
                                .padding(.top, 8)
                                .padding(.leading, 5)
                                .allowsHitTesting(false)
                        }
                        TextEditor(text: $store.memo)
                            .font(Typography.body)
                            .frame(minHeight: 60, maxHeight: 120)
                            .scrollContentBackground(.hidden)
                            .background(.clear)
                    }
                }
            }
        }
    }

    // MARK: - Generate Button

    private var generateButtonBar: some View {
        Button {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            Haptics.impact(.medium)
            store.send(.generateTapped)
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .semibold))
                Text(store.placeCount == 1 ? "장소 추천받기" : "코스 만들기")
                    .font(Typography.body.weight(.bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(canGenerate ? Brand.pink : Color(.tertiaryLabel))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: canGenerate ? Brand.pink.opacity(0.35) : .clear, radius: 12, x: 0, y: 4)
        }
        .disabled(!canGenerate)
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
        .background(.regularMaterial)
    }

    // MARK: - Helpers

    private func iconBadge(_ systemName: String, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.12))
                .frame(width: 36, height: 36)
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(color)
        }
    }
}

private struct WishlistChip: View {
    let name: String
    let selected: Bool
    let disabled: Bool
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Button(action: onTap) {
                HStack(spacing: 5) {
                    if selected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                    }
                    Text(name)
                        .font(.system(size: 12, weight: selected ? .semibold : .regular))
                        .lineLimit(1)
                }
                .padding(.leading, selected ? 10 : 12)
                .padding(.trailing, 6)
                .padding(.vertical, 7)
            }
            .buttonStyle(.plain)
            .foregroundStyle(selected ? Brand.pink : (disabled ? Color(.tertiaryLabel) : .primary))

            if selected {
                Button(action: onDelete) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Brand.pink.opacity(0.7))
                        .padding(.trailing, 8)
                        .padding(.vertical, 7)
                }
                .buttonStyle(.plain)
            }
        }
        .background(selected ? Brand.softPink : Color(.tertiarySystemFill))
        .clipShape(Capsule())
        .overlay {
            if selected {
                Capsule().stroke(Brand.pink.opacity(0.4), lineWidth: 1)
            }
        }
        .opacity(disabled ? 0.4 : 1)
        .animation(.spring(response: 0.2), value: selected)
    }
}
