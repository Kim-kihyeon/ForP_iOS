import SwiftUI
import ComposableArchitecture
import CoreSharedUI

public struct PartnerView: View {
    @Bindable var store: StoreOf<PartnerFeature>

    private let categories: [(emoji: String, name: String)] = [
        ("☕", "카페"), ("🍳", "브런치"), ("🍽️", "음식점"), ("🍸", "술/바"),
        ("🎬", "영화"), ("🌿", "공원"), ("🖼️", "전시"), ("🎭", "문화"),
        ("🛍️", "쇼핑"), ("🎯", "액티비티"), ("🚗", "드라이브"), ("🎤", "노래방"),
        ("🏸", "스포츠"), ("🌃", "야경"), ("🧘", "힐링"),
    ]

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
                        notesSection
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.md)
                    .padding(.bottom, Spacing.sm)
                }

                saveButtonBar
            }

            if store.isLoading { LoadingView() }
        }
        .navigationTitle(store.mode == .create ? "파트너 등록" : "파트너 수정")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Brand.pink, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .alert($store.scope(state: \.alert, action: \.alert))
    }

    // MARK: - Sections

    private var nicknameSection: some View {
        PartnerFormCard {
            HStack(spacing: Spacing.md) {
                iconBadge("person.fill", color: Brand.pink)
                VStack(alignment: .leading, spacing: 4) {
                    Text("파트너 이름")
                        .font(Typography.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                    TextField("닉네임", text: $store.nickname)
                        .font(Typography.body.weight(.medium))
                }
            }
        }
    }

    private var categorySection: some View {
        PartnerFormCard {
            HStack(spacing: Spacing.md) {
                iconBadge("tag.fill", color: Brand.pink)
                VStack(alignment: .leading, spacing: 2) {
                    Text("카테고리")
                        .font(Typography.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text("탭: 선호(핑크) → 비선호(빨강) → 해제")
                        .font(.system(size: 10))
                        .foregroundStyle(Color(.tertiaryLabel))
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
                    isDisliked ? Color(red: 1.0, green: 0.35, blue: 0.35) :
                    Color(.secondarySystemBackground)
                )
                .foregroundStyle((isPreferred || isDisliked) ? Color.white : Color.primary)
                .clipShape(Capsule())
                .onTapGesture { store.send(.categoryTapped(item.name)) }
            }
        }
    }

    private var notesSection: some View {
        PartnerFormCard {
            HStack(alignment: .top, spacing: Spacing.md) {
                iconBadge("note.text", color: Color(red: 1.0, green: 0.6, blue: 0.2))
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
                    .background(store.nickname.isEmpty ? Color(.tertiaryLabel) : Brand.pink)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: store.nickname.isEmpty ? .clear : Brand.pink.opacity(0.35), radius: 12, x: 0, y: 4)
            }
            .disabled(store.nickname.isEmpty)
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

private struct PartnerFormCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            content
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}
