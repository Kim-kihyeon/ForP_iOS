import SwiftUI
import ComposableArchitecture
import CoreSharedUI
import Domain

public struct CourseGenerateView: View {
    @Bindable var store: StoreOf<CourseGenerateFeature>
    @State private var pendingDeleteId: UUID? = nil
    @State private var showExitConfirm = false
    @FocusState private var locationFocused: Bool
    @Environment(\.dismiss) private var dismiss

    public init(store: StoreOf<CourseGenerateFeature>) {
        self.store = store
    }

    public var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        locationSection
                        dateSection
                        placeCountSection
                        themeSection
                        if !store.wishlistPlaces.isEmpty {
                            wishlistSection
                        }
                        memoSection
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.md)
                    .padding(.bottom, Spacing.sm)
                }

                generateButtonBar
            }

            if store.isGenerating {
                ZStack(alignment: .bottom) {
                    CourseLoadingView()
                    Button {
                        Haptics.impact(.light)
                        store.send(.cancelGenerationTapped)
                    } label: {
                        Text("취소")
                            .font(Typography.body.weight(.medium))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, Spacing.xl)
                            .padding(.vertical, Spacing.sm)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                    }
                    .padding(.bottom, 60)
                }
            }
        }
        .hideKeyboardOnTap()
        .disableSwipeBack()
        .onAppear { store.send(.onAppear) }
        .navigationTitle("코스 만들기")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
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
        .alert("코스 만들기를 그만할까요?", isPresented: $showExitConfirm) {
            Button("나가기", role: .destructive) { dismiss() }
            Button("계속하기", role: .cancel) {}
        } message: {
            Text("입력한 내용이 사라져요.")
        }
        .tint(Brand.pink)
        .toolbarBackground(Brand.softPink, for: .navigationBar)
        .alert("코스 생성 실패", isPresented: Binding(
            get: { store.errorMessage != nil },
            set: { if !$0 { store.send(.binding(.set(\.errorMessage, nil))) } }
        )) {
            Button("다시 시도") { store.send(.retryTapped) }
            Button("취소", role: .cancel) { store.send(.binding(.set(\.errorMessage, nil))) }
        } message: {
            Text(store.errorMessage ?? "")
        }
        .alert("찜 목록에서 삭제할까요?", isPresented: Binding(
            get: { pendingDeleteId != nil },
            set: { if !$0 { pendingDeleteId = nil } }
        )) {
            Button("삭제", role: .destructive) {
                if let id = pendingDeleteId {
                    store.send(.removeFromWishlist(id))
                    pendingDeleteId = nil
                }
            }
            Button("취소", role: .cancel) { pendingDeleteId = nil }
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
                            HStack(spacing: 6) {
                                TextField(
                                    store.selectedLocations.isEmpty ? "홍대, 강남, 사당역..." : "장소 추가...",
                                    text: $store.locationQuery
                                )
                                .font(Typography.body.weight(.medium))
                                .focused($locationFocused)
                                if store.isSearchingLocation {
                                    ProgressView().scaleEffect(0.7)
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
            }
        }
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

    // MARK: - Date

    private var dateSection: some View {
        FormCard {
            HStack(spacing: Spacing.md) {
                iconBadge("calendar", color: Brand.iconBlue)
                Text("언제?")
                    .font(Typography.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                DatePicker("", selection: $store.date, in: Date()..., displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .environment(\.locale, Locale(identifier: "ko_KR"))
                    .fixedSize()
            }
            let daysFromNow = Calendar.current.dateComponents([.day], from: Date(), to: store.date).day ?? 0
            HStack(spacing: 4) {
                Image(systemName: daysFromNow <= 4 ? "cloud.sun.fill" : "thermometer.medium")
                    .font(.caption2)
                Text(daysFromNow <= 4 ? "실제 날씨 예보가 코스에 반영돼요" : "계절 기반으로 반영돼요")
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
                iconBadge("mappin.and.ellipse", color: Brand.iconPurple)
                Text("몇 곳?")
                    .font(Typography.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                HStack(spacing: Spacing.lg) {
                    Button {
                        if store.placeCount > 2 {
                            store.send(.binding(.set(\.placeCount, store.placeCount - 1)))
                        }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(store.placeCount > 2 ? Brand.pink : Color(.tertiaryLabel))
                    }
                    Text("\(store.placeCount)")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .frame(minWidth: 24)
                    Button {
                        if store.placeCount < 6 {
                            store.send(.binding(.set(\.placeCount, store.placeCount + 1)))
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(store.placeCount < 6 ? Brand.pink : Color(.tertiaryLabel))
                    }
                }
            }
        }
    }

    // MARK: - Theme

    private let availableThemes: [(String, String)] = [
        ("로맨틱", "heart.fill"),
        ("맛집 탐방", "fork.knife"),
        ("카페 투어", "cup.and.saucer.fill"),
        ("야외·자연", "leaf.fill"),
        ("문화·예술", "paintpalette.fill"),
        ("액티비티", "figure.walk"),
        ("쇼핑", "bag.fill"),
        ("야경", "moon.stars.fill"),
    ]

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
            let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(availableThemes, id: \.0) { theme, icon in
                    let selected = store.selectedThemes.contains(theme)
                    Button {
                        Haptics.selection()
                        var themes = store.selectedThemes
                        if selected {
                            themes.removeAll { $0 == theme }
                        } else {
                            themes.append(theme)
                        }
                        store.send(.binding(.set(\.selectedThemes, themes)))
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: icon)
                                .font(.system(size: 16))
                            Text(theme)
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
        }
    }

    // MARK: - Wishlist

    private var wishlistSection: some View {
        FormCard {
            HStack(spacing: Spacing.md) {
                iconBadge("bookmark.fill", color: Brand.iconOrange)
                Text("찜한 장소 포함")
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
                            pendingDeleteId = place.id
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
                    TextField("실내 위주로, 예산 10만원, 프로포즈 예정...", text: $store.memo, axis: .vertical)
                        .font(Typography.body)
                        .lineLimit(2...4)
                }
            }
        }
    }

    // MARK: - Generate Button

    private var generateButtonBar: some View {
        VStack(spacing: 0) {
            Divider().opacity(0.5)
            Button {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                Haptics.impact(.medium)
                store.send(.generateTapped)
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .semibold))
                    Text("코스 생성하기")
                        .font(Typography.body.weight(.bold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(store.selectedLocations.isEmpty ? Color(.tertiaryLabel) : Brand.pink)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: store.selectedLocations.isEmpty ? .clear : Brand.pink.opacity(0.35), radius: 12, x: 0, y: 4)
            }
            .disabled(store.selectedLocations.isEmpty)
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.lg)
            .background(.ultraThinMaterial)
        }
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
            } else {
                Color.clear.frame(width: 0)
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
