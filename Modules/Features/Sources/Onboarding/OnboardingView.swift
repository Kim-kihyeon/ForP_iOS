import SwiftUI
import ComposableArchitecture
import CoreSharedUI
import Domain

public struct OnboardingView: View {
    @Bindable var store: StoreOf<OnboardingFeature>
    @State private var showIntro = true
    @State private var currentStep = 0
    @State private var customBlacklistInput = ""

    // Intro animations
    @State private var appeared = false
    @State private var ef1: CGFloat = 0
    @State private var ef2: CGFloat = 0
    @State private var ef3: CGFloat = 0
    @State private var ef4: CGFloat = 0
    @State private var ef5: CGFloat = 0
    @State private var ef6: CGFloat = 0
    @State private var buttonScale: CGFloat = 1.0

    private let totalSteps = 4
    private let categories = PreferenceOptions.categories
    private let themes = PreferenceOptions.themes
    private let blacklistPresets = PreferenceOptions.blacklistPresets

    public init(store: StoreOf<OnboardingFeature>) {
        self.store = store
    }

    public var body: some View {
        ZStack {
            if showIntro {
                introScreen
                    .transition(.asymmetric(insertion: .opacity, removal: .move(edge: .leading).combined(with: .opacity)))
            } else {
                onboardingFlow
                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
            }

            if store.isLoading { LoadingView() }
        }
        .hideKeyboardOnTap()
        .animation(.easeInOut(duration: 0.4), value: showIntro)
        .navigationBarBackButtonHidden()
        .alert($store.scope(state: \.alert, action: \.alert))
        .onAppear { store.send(.onAppear) }
    }

    // MARK: - Intro Screen

    private var introScreen: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.90, green: 0.15, blue: 0.35),
                    Brand.pink,
                    Color(red: 1.0, green: 0.58, blue: 0.38),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Blurred depth circles
            Circle()
                .fill(.white.opacity(0.12))
                .frame(width: 380)
                .blur(radius: 70)
                .offset(x: -80, y: -320)

            Circle()
                .fill(.white.opacity(0.08))
                .frame(width: 260)
                .blur(radius: 50)
                .offset(x: 150, y: 180)

            // Floating emojis
            Group {
                Text("💕").font(.system(size: 46)).offset(x: -140, y: -270 + ef1).opacity(appeared ? 0.55 : 0).rotationEffect(.degrees(-15))
                Text("✨").font(.system(size: 26)).offset(x: 140, y: -310 + ef2).opacity(appeared ? 0.45 : 0)
                Text("💝").font(.system(size: 34)).offset(x: 148, y: -140 + ef3).opacity(appeared ? 0.4 : 0).rotationEffect(.degrees(12))
                Text("🌸").font(.system(size: 28)).offset(x: -148, y: 60 + ef4).opacity(appeared ? 0.45 : 0).rotationEffect(.degrees(-8))
                Text("✨").font(.system(size: 18)).offset(x: -90, y: 300 + ef5).opacity(appeared ? 0.35 : 0)
                Text("💕").font(.system(size: 22)).offset(x: 138, y: 250 + ef6).opacity(appeared ? 0.38 : 0).rotationEffect(.degrees(20))
            }
            .animation(.easeOut(duration: 0.6).delay(0.1), value: appeared)

            // Main content
            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 24) {
                    VStack(spacing: 6) {
                        Text("ForP")
                            .font(.system(size: 60, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .scaleEffect(appeared ? 1 : 0.8)
                            .opacity(appeared ? 1 : 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.15), value: appeared)
                        Text("FOR PARTNERS")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.55))
                            .tracking(5)
                            .opacity(appeared ? 1 : 0)
                            .animation(.easeOut(duration: 0.5).delay(0.35), value: appeared)
                    }

                    Rectangle()
                        .fill(.white.opacity(0.3))
                        .frame(width: appeared ? 36 : 0, height: 1)
                        .animation(.easeOut(duration: 0.5).delay(0.45), value: appeared)

                    Text("우리만의\n데이트 코스")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 16)
                        .animation(.easeOut(duration: 0.6).delay(0.5), value: appeared)
                }

                Spacer()

                VStack(spacing: 14) {
                    Text("취향에 딱 맞는 코스를 만들어드려요")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.65))
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.5).delay(0.7), value: appeared)

                    Button {
                        withAnimation(.easeInOut(duration: 0.4)) { showIntro = false }
                    } label: {
                        Text("취향 설정하기")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(Brand.pink)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(.white)
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.12), radius: 24, x: 0, y: 8)
                    }
                    .scaleEffect(buttonScale)
                    .padding(.horizontal, Spacing.lg)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.8), value: appeared)
                }
                .padding(.bottom, Spacing.xl)
            }
        }
        .onAppear {
            appeared = true
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) { ef1 = 14 }
            withAnimation(.easeInOut(duration: 1.9).repeatForever(autoreverses: true).delay(0.5)) { ef2 = -12 }
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true).delay(0.8)) { ef3 = 10 }
            withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true).delay(0.3)) { ef4 = -14 }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true).delay(1.1)) { ef5 = 12 }
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true).delay(0.6)) { ef6 = -10 }
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true).delay(1.2)) { buttonScale = 1.03 }
        }
    }

    // MARK: - Onboarding Flow

    private var onboardingFlow: some View {
        ZStack(alignment: .bottom) {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                progressBar

                TabView(selection: stepBinding) {
                    locationPage.tag(0)
                    categoryPage.tag(1)
                    blacklistPage.tag(2)
                    themePage.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .highPriorityGesture(DragGesture())
                .animation(.easeInOut(duration: 0.3), value: currentStep)

                bottomBar
            }
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalSteps, id: \.self) { i in
                Capsule()
                    .fill(i <= currentStep ? Brand.pink : Color(.tertiarySystemFill))
                    .frame(height: 4)
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.md)
        .padding(.bottom, Spacing.sm)
    }

    // MARK: - Pages

    private var locationPage: some View {
        pageContainer(icon: "person.crop.circle.fill", title: "기본 정보를 알려주세요", subtitle: "닉네임과 자주 가는 동네를 설정해요") {
            VStack(alignment: .leading, spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("닉네임")
                        .font(Typography.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                    HStack(spacing: Spacing.md) {
                        Image(systemName: "person.fill")
                            .foregroundStyle(.secondary)
                        TextField("예: 키키", text: $store.nickname)
                            .font(Typography.body)
                            .textInputAutocapitalization(.never)
                        Button {
                            Haptics.selection()
                            store.send(.randomNicknameTapped)
                        } label: {
                            Image(systemName: "dice.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Brand.pink)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(Spacing.md)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("주로 가는 동네")
                        .font(Typography.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)

                    if let selected = store.selectedLocation {
                        selectedLocationChip(selected)
                    } else {
                        HStack(spacing: Spacing.md) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.secondary)
                            TextField("예: 홍대, 강남, 성수동", text: $store.location)
                                .font(Typography.body)
                                .textInputAutocapitalization(.never)
                            if store.isSearchingLocation {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                        .padding(Spacing.md)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        if !store.locationSuggestions.isEmpty {
                            VStack(spacing: 0) {
                                ForEach(Array(store.locationSuggestions.enumerated()), id: \.offset) { index, place in
                                    Button {
                                        Haptics.selection()
                                        store.send(.locationSuggestionSelected(place))
                                    } label: {
                                        HStack(spacing: Spacing.sm) {
                                            Image(systemName: "mappin.circle.fill")
                                                .foregroundStyle(Brand.pink)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(place.placeName ?? place.keyword)
                                                    .font(Typography.caption.weight(.semibold))
                                                    .foregroundStyle(.primary)
                                                if let address = place.address {
                                                    Text(address)
                                                        .font(Typography.caption2)
                                                        .foregroundStyle(.secondary)
                                                        .lineLimit(1)
                                                }
                                            }
                                            Spacer()
                                        }
                                        .padding(.vertical, Spacing.sm)
                                        .padding(.horizontal, Spacing.md)
                                    }
                                    .buttonStyle(.plain)

                                    if index < store.locationSuggestions.count - 1 {
                                        Divider().padding(.leading, 44)
                                    }
                                }
                            }
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
            }
        }
    }

    private var categoryPage: some View {
        pageContainer(icon: "heart.fill", title: "어떤 걸 좋아해요?", subtitle: "탭해서 선호 · 비선호를 표시해요") {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack(spacing: 6) {
                    Label("선호", systemImage: "hand.tap.fill")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Brand.pink)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Brand.softPink)
                        .clipShape(Capsule())
                    Text("→")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Text("비선호")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Brand.iconRed)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Brand.iconRed.opacity(0.1))
                        .clipShape(Capsule())
                    Text("→")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Text("해제")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                categoryChipGrid
            }
        }
    }

    private var blacklistPage: some View {
        pageContainer(icon: "nosign", title: "피하고 싶은 게 있나요?", subtitle: "알레르기나 제외할 음식을 설정해요") {
            blacklistPicker
        }
    }

    private var themePage: some View {
        pageContainer(icon: "sparkles", title: "어떤 분위기를 좋아해요?", subtitle: "여러 개 선택할 수 있어요") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: Spacing.sm) {
                ForEach(themes, id: \.name) { item in
                    let isSelected = store.preferredThemes.contains(item.name)
                    HStack(spacing: 4) {
                        Text(item.emoji).font(.system(size: 14))
                        Text(item.name).font(Typography.caption)
                    }
                    .padding(.horizontal, Spacing.sm + 2)
                    .padding(.vertical, Spacing.xs + 2)
                    .frame(maxWidth: .infinity)
                    .background(isSelected ? Brand.pink : Color(.secondarySystemBackground))
                    .foregroundStyle(isSelected ? Color.white : Color.primary)
                    .clipShape(Capsule())
                    .onTapGesture { store.send(.themeToggled(item.name)) }
                }
            }
        }
    }

    private func pageContainer<Content: View>(
        icon: String,
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [Brand.pink, Color(red: 1.0, green: 0.6, blue: 0.4)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 220)
                .overlay {
                    VStack(spacing: Spacing.md) {
                        ZStack {
                            Circle()
                                .fill(.white.opacity(0.2))
                                .frame(width: 72, height: 72)
                            Image(systemName: icon)
                                .font(.system(size: 30, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        VStack(spacing: 4) {
                            Text(title)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(.white)
                            Text(subtitle)
                                .font(Typography.caption)
                                .foregroundStyle(.white.opacity(0.85))
                        }
                    }
                }

                content()
                    .padding(Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Category Chip Grid

    private var categoryChipGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: Spacing.sm) {
            ForEach(categories, id: \.name) { item in
                let isPreferred = store.preferredCategories.contains(item.name)
                let isDisliked = store.dislikedCategories.contains(item.name)
                HStack(spacing: 4) {
                    Text(item.emoji).font(.system(size: 14))
                    if isPreferred {
                        Image(systemName: "heart.fill").font(.system(size: 8)).foregroundStyle(.white.opacity(0.8))
                    } else if isDisliked {
                        Image(systemName: "xmark").font(.system(size: 8, weight: .bold)).foregroundStyle(.white.opacity(0.8))
                    }
                    Text(item.name).font(Typography.caption)
                }
                .padding(.horizontal, Spacing.sm + 2)
                .padding(.vertical, Spacing.xs + 2)
                .frame(maxWidth: .infinity)
                .background(
                    isPreferred ? Brand.pink :
                    isDisliked ? Brand.iconRed :
                    Color(.secondarySystemBackground)
                )
                .foregroundStyle((isPreferred || isDisliked) ? Color.white : Color.primary)
                .clipShape(Capsule())
                .onTapGesture { store.send(.categoryTapped(item.name)) }
            }
        }
    }

    private var blacklistPicker: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("절대 제외 음식/장소 · 선택사항")
                .font(Typography.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("알레르기나 피하고 싶은 음식을 추가해요")
                .font(Typography.caption2)
                .foregroundStyle(.tertiary)

            FlowLayout(spacing: 8) {
                ForEach(blacklistPresets, id: \.name) { item in
                    let isSelected = store.foodBlacklist.contains(item.name)
                    Button {
                        Haptics.selection()
                        store.send(.blacklistToggled(item.name))
                    } label: {
                        HStack(spacing: 4) {
                            Text(item.emoji).font(.system(size: 13))
                            Text(item.name).font(.system(size: 12, weight: .medium))
                            if isSelected {
                                Image(systemName: "xmark").font(.system(size: 9, weight: .bold))
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(isSelected ? Color(.systemRed).opacity(0.12) : Color(.tertiarySystemFill))
                        .foregroundStyle(isSelected ? Color(.systemRed) : Color(.secondaryLabel))
                        .clipShape(Capsule())
                        .overlay {
                            if isSelected {
                                Capsule().stroke(Color(.systemRed).opacity(0.4), lineWidth: 1)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }

                ForEach(store.foodBlacklist.filter { item in !blacklistPresets.map(\.name).contains(item) }, id: \.self) { item in
                    HStack(spacing: 4) {
                        Text(item).font(.system(size: 12, weight: .medium))
                        Button {
                            store.send(.blacklistRemoved(item))
                        } label: {
                            Image(systemName: "xmark").font(.system(size: 9, weight: .bold))
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(.systemRed).opacity(0.12))
                    .foregroundStyle(Color(.systemRed))
                    .clipShape(Capsule())
                    .overlay { Capsule().stroke(Color(.systemRed).opacity(0.4), lineWidth: 1) }
                }
            }

            HStack(spacing: 8) {
                TextField("직접 입력 (예: 고수, 오이)", text: $customBlacklistInput)
                    .font(.system(size: 14))
                    .onSubmit { addCustomBlacklist() }
                Button(action: addCustomBlacklist) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(customBlacklistInput.isEmpty ? Color(.tertiaryLabel) : Color(.systemRed))
                }
                .disabled(customBlacklistInput.isEmpty)
            }
            .padding(Spacing.sm)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.top, Spacing.sm)
    }

    private func selectedLocationChip(_ place: CoursePlace) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "mappin.circle.fill")
                .foregroundStyle(Brand.pink)
            VStack(alignment: .leading, spacing: 2) {
                Text(place.placeName ?? place.keyword)
                    .font(Typography.body.weight(.semibold))
                    .foregroundStyle(.primary)
                if let address = place.address, !address.isEmpty {
                    Text(address)
                        .font(Typography.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            Button {
                Haptics.selection()
                store.send(.selectedLocationCleared)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color(.tertiaryLabel))
            }
            .buttonStyle(.plain)
        }
        .padding(Spacing.md)
        .background(Brand.softPink)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Brand.pink.opacity(0.35), lineWidth: 1)
        }
    }

    private func addCustomBlacklist() {
        store.send(.blacklistCustomAdded(customBlacklistInput))
        customBlacklistInput = ""
    }

    // MARK: - Bottom Bar

    private var stepBinding: Binding<Int> {
        Binding(
            get: { currentStep },
            set: { nextStep in
                guard nextStep <= currentStep || (currentStep..<nextStep).allSatisfy({ canProceed(from: $0) }) else {
                    Haptics.notification(.warning)
                    return
                }
                currentStep = nextStep
            }
        )
    }

    private var canProceed: Bool {
        canProceed(from: currentStep)
    }

    private func canProceed(from step: Int) -> Bool {
        switch step {
        case 0:
            return !store.nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                store.selectedLocation != nil
        case 1:
            return !store.preferredCategories.isEmpty || !store.dislikedCategories.isEmpty
        case 2:
            return true
        case 3:
            return !store.preferredThemes.isEmpty
        default: return true
        }
    }

    private var bottomBar: some View {
        VStack(spacing: Spacing.xs) {
            if !canProceed, let message = proceedHint {
                Text(message)
                    .font(Typography.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            HStack(spacing: Spacing.md) {
                if currentStep > 0 {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) { currentStep -= 1 }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Brand.pink)
                            .frame(width: 52, height: 52)
                            .background(Brand.softPink)
                            .clipShape(Circle())
                    }
                }

                Button {
                    if currentStep < totalSteps - 1 {
                        guard canProceed else {
                            Haptics.notification(.warning)
                            return
                        }
                        withAnimation(.easeInOut(duration: 0.3)) { currentStep += 1 }
                    } else {
                        store.send(.saveTapped)
                    }
                } label: {
                    Text(currentStep == totalSteps - 1 ? "완료" : "다음")
                        .font(Typography.body.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(canProceed ? Brand.pink : Color(.tertiaryLabel))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: canProceed ? Brand.pink.opacity(0.3) : .clear, radius: 10, x: 0, y: 4)
                }
                .disabled(!canProceed)
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
        .background(.regularMaterial)
    }

    private var proceedHint: String? {
        switch currentStep {
        case 0:
            if store.nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return "닉네임을 입력하면 다음으로 갈 수 있어요"
            }
            return "검색 결과에서 자주 가는 동네를 선택해주세요"
        case 1:
            return "좋아하거나 피하고 싶은 카테고리를 하나 이상 선택해주세요"
        case 2:
            return nil
        case 3:
            return "선호하는 분위기를 하나 이상 선택해주세요"
        default:
            return nil
        }
    }
}
