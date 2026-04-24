import SwiftUI
import ComposableArchitecture
import CoreSharedUI
import Domain

public struct ProfileView: View {
    @Bindable var store: StoreOf<ProfileFeature>
    @State private var showExitConfirm = false
    @State private var customBlacklistInput = ""
    @Environment(\.dismiss) private var dismiss

    private let categories: [(emoji: String, name: String)] = [
        ("☕", "카페"), ("🍳", "브런치"), ("🍽️", "음식점"), ("🍸", "술/바"),
        ("🎬", "영화"), ("🌿", "공원"), ("🖼️", "전시"), ("🎭", "문화"),
        ("🛍️", "쇼핑"), ("🎯", "액티비티"), ("🚗", "드라이브"), ("🎤", "노래방"),
        ("🏸", "스포츠"), ("🌃", "야경"), ("🧘", "힐링"),
    ]

    public init(store: StoreOf<ProfileFeature>) {
        self.store = store
    }

    public var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    basicSection
                    preferredSection
                    dislikedSection
                    blacklistSection
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.md)
                .padding(.bottom, 80)
            }

            if store.isSaving { LoadingView() }

            if store.showSaved {
                VStack {
                    Spacer()
                    Label("저장됐어요", systemImage: "checkmark.circle.fill")
                        .font(Typography.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.sm)
                        .background(Color.green.opacity(0.9))
                        .clipShape(Capsule())
                        .padding(.bottom, 100)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .animation(.spring(response: 0.3), value: store.showSaved)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            saveBar
        }
        .hideKeyboardOnTap()
        .navigationTitle("내 프로필")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    if store.hasChanges {
                        showExitConfirm = true
                    } else {
                        dismiss()
                    }
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
        .alert("저장하지 않고 나갈까요?", isPresented: $showExitConfirm) {
            Button("나가기", role: .destructive) { dismiss() }
            Button("계속 수정", role: .cancel) {}
        } message: {
            Text("변경사항이 저장되지 않아요.")
        }
        .tint(Brand.pink)
        .toolbarBackground(Brand.softPink, for: .navigationBar)
        .alert($store.scope(state: \.alert, action: \.alert))
    }

    // MARK: - Basic

    private var basicSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("기본 정보")
            VStack(spacing: 0) {
                fieldRow(icon: "person.fill", iconColor: Brand.pink, label: "닉네임") {
                    TextField("닉네임", text: $store.nickname)
                        .font(Typography.body)
                }
                Divider().padding(.leading, 52)
                fieldRow(icon: "location.fill", iconColor: Brand.iconBlue, label: "자주 가는 지역") {
                    TextField("강남, 홍대, 성수동...", text: $store.location)
                        .font(Typography.body)
                }
            }
            .padding(Spacing.md)
            .cardStyle()
        }
    }

    // MARK: - Preferred

    private var preferredSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("좋아하는 것")
            categoryGrid(selected: $store.preferredCategories, exclude: store.dislikedCategories, accentColor: Brand.pink)
        }
    }

    // MARK: - Disliked

    private var dislikedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("싫어하는 것")
            categoryGrid(selected: $store.dislikedCategories, exclude: store.preferredCategories, accentColor: Color(.secondaryLabel))
        }
    }

    // MARK: - Blacklist

    private let blacklistPresets: [(String, String)] = [
        ("🥜", "견과류"), ("🦐", "해산물"), ("🥛", "유제품"), ("🌾", "글루텐"),
        ("🌶️", "매운 음식"), ("🍺", "알코올"), ("🥩", "육류"), ("🐷", "돼지고기"),
        ("🐟", "날음식/회"), ("☕", "카페인")
    ]

    private var blacklistSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("절대 제외 음식/장소")
            VStack(alignment: .leading, spacing: 12) {
                FlowLayout(spacing: 8) {
                    ForEach(blacklistPresets, id: \.1) { emoji, name in
                        let isSelected = store.foodBlacklist.contains(name)
                        Button {
                            Haptics.selection()
                            if isSelected {
                                store.foodBlacklist.removeAll { $0 == name }
                            } else {
                                store.foodBlacklist.append(name)
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(emoji).font(.system(size: 13))
                                Text(name).font(.system(size: 12, weight: .medium))
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
                    ForEach(store.foodBlacklist.filter { item in !blacklistPresets.map(\.1).contains(item) }, id: \.self) { item in
                        HStack(spacing: 4) {
                            Text(item).font(.system(size: 12, weight: .medium))
                            Button {
                                store.foodBlacklist.removeAll { $0 == item }
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
            }
            .padding(Spacing.md)
            .cardStyle()
        }
    }

    private func addCustomBlacklist() {
        let trimmed = customBlacklistInput.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !store.foodBlacklist.contains(trimmed) else { return }
        store.foodBlacklist.append(trimmed)
        customBlacklistInput = ""
    }

    // MARK: - Category Grid

    private func categoryGrid(selected: Binding<[String]>, exclude: [String], accentColor: Color) -> some View {
        let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(categories, id: \.name) { emoji, name in
                let isSelected = selected.wrappedValue.contains(name)
                let isExcluded = exclude.contains(name)
                Button {
                    guard !isExcluded else { return }
                    Haptics.selection()
                    if isSelected {
                        selected.wrappedValue.removeAll { $0 == name }
                    } else {
                        selected.wrappedValue.append(name)
                    }
                } label: {
                    ZStack(alignment: .topTrailing) {
                        VStack(spacing: 3) {
                            Text(emoji).font(.system(size: 20))
                            Text(name)
                                .font(.system(size: 10, weight: .medium))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            isExcluded ? Color(.tertiarySystemFill).opacity(0.4) :
                            isSelected ? accentColor.opacity(0.12) : Color(.tertiarySystemFill)
                        )
                        .foregroundStyle(
                            isExcluded ? Color(.tertiaryLabel) :
                            isSelected ? accentColor : Color(.secondaryLabel)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(accentColor.opacity(0.5), lineWidth: 1.5)
                            }
                        }
                        if isExcluded {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(Color(.tertiaryLabel))
                                .padding(3)
                        }
                    }
                }
                .buttonStyle(.plain)
                .disabled(isExcluded)
            }
        }
        .padding(Spacing.md)
        .cardStyle()
    }

    // MARK: - Save Bar

    private var saveBar: some View {
        Button { Haptics.notification(.success); store.send(.saveTapped) } label: {
            Text("저장하기")
                .font(Typography.body.weight(.bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(store.nickname.isEmpty ? Color(.tertiaryLabel) : Brand.pink)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: store.nickname.isEmpty ? .clear : Brand.pink.opacity(0.3), radius: 10, x: 0, y: 4)
        }
        .disabled(store.nickname.isEmpty)
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
        .background(.regularMaterial)
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(.caption2, design: .default, weight: .semibold))
            .foregroundStyle(.secondary)
            .padding(.leading, 4)
    }

    private func fieldRow<Content: View>(icon: String, iconColor: Color, label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(iconColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(Typography.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                content()
            }
        }
        .padding(.vertical, 4)
    }
}
