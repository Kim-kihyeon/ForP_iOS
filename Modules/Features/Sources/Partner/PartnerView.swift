import SwiftUI
import ComposableArchitecture
import CoreSharedUI

public struct PartnerView: View {
    @Bindable var store: StoreOf<PartnerFeature>
    @State private var showExitConfirm = false
    @State private var customBlacklistInput = ""
    @Environment(\.dismiss) private var dismiss

    private let blacklistPresets = PreferenceOptions.blacklistPresets

    public init(store: StoreOf<PartnerFeature>) {
        self.store = store
    }

    public var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    nicknameSection
                    blacklistSection
                    notesSection
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.md)
                .padding(.bottom, 80)
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
        .safeAreaInset(edge: .bottom, spacing: 0) {
            saveButtonBar
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
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("기본 정보")
            VStack(spacing: 14) {
                fieldRow(icon: "person.fill", iconColor: Brand.pink, label: "파트너 이름") {
                    Group {
                        if store.isConnected {
                            Text(store.nickname)
                                .font(Typography.body)
                                .foregroundStyle(.secondary)
                        } else {
                            TextField("닉네임", text: $store.nickname)
                                .font(Typography.body)
                                .textInputAutocapitalization(.never)
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.md + 2)
            .cardStyle()
        }
    }

    private var blacklistSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("절대 제외 음식/장소")
            VStack(alignment: .leading, spacing: 12) {
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
                                Haptics.selection()
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

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("메모")
            VStack(spacing: 14) {
                fieldRow(icon: "note.text", iconColor: Brand.iconOrange, label: "파트너 메모") {
                    TextField("자유롭게 적어주세요", text: $store.notes, axis: .vertical)
                        .font(Typography.body)
                        .lineLimit(3...6)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.md + 2)
            .cardStyle()
        }
    }

    // MARK: - Save Button Bar

    private var saveButtonBar: some View {
        Button {
            Haptics.notification(.success)
            store.send(.saveTapped)
        } label: {
            Text("저장하기")
                .font(Typography.body.weight(.bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background((store.isConnected ? false : store.nickname.isEmpty) ? Color(.tertiaryLabel) : Brand.pink)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: (store.isConnected ? false : store.nickname.isEmpty) ? .clear : Brand.pink.opacity(0.3), radius: 10, x: 0, y: 4)
        }
        .disabled(store.isConnected ? false : store.nickname.isEmpty)
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
        HStack(alignment: .top, spacing: Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(iconColor)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(label)
                    .font(Typography.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                content()
                    .frame(minHeight: 26)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 6)
    }
}
