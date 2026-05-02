import SwiftUI
import ComposableArchitecture
import CoreSharedUI

public struct PartnerView: View {
    @Bindable var store: StoreOf<PartnerFeature>
    @State private var showExitConfirm = false
    @State private var customBlacklistInput = ""
    @Environment(\.dismiss) private var dismiss

    private let categories = PreferenceOptions.categories
    private let blacklistPresets = PreferenceOptions.blacklistPresets

    public init(store: StoreOf<PartnerFeature>) {
        self.store = store
    }

    public var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        nicknameSection
                        categorySection
                        blacklistSection
                        notesSection
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.md)
                    .padding(.bottom, Spacing.sm)
                }

                saveButtonBar
            }

            if store.isLoading { LoadingView() }

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
        .hideKeyboardOnTap()
        .navigationTitle(store.mode == .create ? "파트너 등록" : "파트너 수정")
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

    // MARK: - Sections

    private var nicknameSection: some View {
        FormCard {
            HStack(spacing: Spacing.md) {
                iconBadge("person.fill", color: Brand.pink)
                VStack(alignment: .leading, spacing: 4) {
                    Text("파트너 이름")
                        .font(Typography.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                    if store.isConnected {
                        Text(store.nickname)
                            .font(Typography.body.weight(.medium))
                            .foregroundStyle(.secondary)
                    } else {
                        TextField("닉네임", text: $store.nickname)
                            .font(Typography.body.weight(.medium))
                    }
                }
            }
        }
    }

    private var categorySection: some View {
        FormCard {
            HStack(spacing: Spacing.md) {
                iconBadge("tag.fill", color: Brand.pink)
                VStack(alignment: .leading, spacing: 2) {
                    Text("카테고리")
                        .font(Typography.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                    if store.isConnected {
                        Text("파트너가 직접 설정한 정보예요")
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                    } else {
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
                    }
                }
            }
            triStateChipGrid
                .padding(.top, 4)
        }
    }

    private var triStateChipGrid: some View {
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
                .onTapGesture { if !store.isConnected { store.send(.categoryTapped(item.name)) } }
            }
        }
    }

    private var blacklistSection: some View {
        FormCard {
            HStack(alignment: .top, spacing: Spacing.md) {
                iconBadge("nosign", color: Color(.systemRed))
                VStack(alignment: .leading, spacing: 8) {
                    Text("절대 제외 음식/장소")
                        .font(Typography.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                    if store.isConnected {
                        Text("파트너가 직접 설정한 정보예요")
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                    }
                    FlowLayout(spacing: 8) {
                        ForEach(blacklistPresets) { item in
                            let isSelected = store.foodBlacklist.contains(item.name)
                            Button {
                                if !store.isConnected {
                                    if isSelected {
                                        store.foodBlacklist.removeAll { $0 == item.name }
                                    } else {
                                        store.foodBlacklist.append(item.name)
                                    }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Text(item.emoji).font(.system(size: 13))
                                    Text(item.name).font(.system(size: 12, weight: .medium))
                                    if isSelected && !store.isConnected {
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
                                if !store.isConnected {
                                    Button {
                                        store.foodBlacklist.removeAll { $0 == item }
                                    } label: {
                                        Image(systemName: "xmark").font(.system(size: 9, weight: .bold))
                                    }
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
                    if !store.isConnected {
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
                }
            }
        }
    }

    private func addCustomBlacklist() {
        let trimmed = customBlacklistInput.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !store.foodBlacklist.contains(trimmed) else { return }
        store.foodBlacklist.append(trimmed)
        customBlacklistInput = ""
    }

    private var notesSection: some View {
        FormCard {
            HStack(alignment: .top, spacing: Spacing.md) {
                iconBadge("note.text", color: Brand.iconOrange)
                VStack(alignment: .leading, spacing: 4) {
                    Text("메모")
                        .font(Typography.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                    TextField("자유롭게 적어주세요", text: $store.notes, axis: .vertical)
                        .font(Typography.body)
                        .lineLimit(3...6)
                }
            }
        }
    }

    // MARK: - Save Button Bar

    private var saveButtonBar: some View {
        VStack(spacing: 0) {
            Divider().opacity(0.5)
            Button {
                store.send(.saveTapped)
            } label: {
                Text("저장")
                    .font(Typography.body.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background((store.isConnected ? false : store.nickname.isEmpty) ? Color(.tertiaryLabel) : Brand.pink)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: (store.isConnected ? false : store.nickname.isEmpty) ? .clear : Brand.pink.opacity(0.35), radius: 12, x: 0, y: 4)
            }
            .disabled(store.isConnected ? false : store.nickname.isEmpty)
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
