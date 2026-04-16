import SwiftUI
import ComposableArchitecture
import CoreSharedUI

public struct PartnerView: View {
    @Bindable var store: StoreOf<PartnerFeature>

    private let categories = ["카페", "음식점", "공원", "문화", "쇼핑", "액티비티"]

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
                        preferredSection
                        dislikedSection
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

    private var preferredSection: some View {
        PartnerFormCard {
            HStack(spacing: Spacing.md) {
                iconBadge("heart.fill", color: Brand.pink)
                Text("선호 카테고리")
                    .font(Typography.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            ChipGrid(items: categories, selected: store.preferredCategories) {
                store.send(.binding(.set(\.preferredCategories, toggle(store.preferredCategories, item: $0))))
            }
            .padding(.top, 4)
        }
    }

    private var dislikedSection: some View {
        PartnerFormCard {
            HStack(spacing: Spacing.md) {
                iconBadge("hand.thumbsdown.fill", color: Color(red: 0.6, green: 0.4, blue: 1.0))
                Text("비선호 카테고리")
                    .font(Typography.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            ChipGrid(items: categories, selected: store.dislikedCategories) {
                store.send(.binding(.set(\.dislikedCategories, toggle(store.dislikedCategories, item: $0))))
            }
            .padding(.top, 4)
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

    private func toggle(_ list: [String], item: String) -> [String] {
        var updated = list
        if updated.contains(item) { updated.removeAll { $0 == item } }
        else { updated.append(item) }
        return updated
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
