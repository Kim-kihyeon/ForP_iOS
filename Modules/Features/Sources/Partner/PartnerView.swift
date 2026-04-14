import SwiftUI
import ComposableArchitecture
import CoreSharedUI

public struct PartnerView: View {
    @Bindable var store: StoreOf<PartnerFeature>

    private let categories = ["카페", "음식점", "공원", "문화", "쇼핑", "액티비티"]
    private let themes = ["조용한", "활동적인", "감성적인", "맛집 탐방", "자연"]

    public init(store: StoreOf<PartnerFeature>) {
        self.store = store
    }

    public var body: some View {
        ZStack {
            Form {
                Section("파트너 이름") {
                    TextField("닉네임", text: $store.nickname)
                }
                Section("파트너 선호") {
                    ChipGrid(items: categories, selected: store.preferredCategories) {
                        store.send(.binding(.set(\.preferredCategories,
                            toggle(store.preferredCategories, item: $0))))
                    }
                }
                Section("파트너 비선호") {
                    ChipGrid(items: categories, selected: store.dislikedCategories) {
                        store.send(.binding(.set(\.dislikedCategories,
                            toggle(store.dislikedCategories, item: $0))))
                    }
                }
                Section("메모") {
                    TextField("자유롭게 적어주세요", text: $store.notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                Section {
                    ForPButton("저장") { store.send(.saveTapped) }
                }
            }
            if store.isLoading { LoadingView() }
        }
        .navigationTitle(store.mode == .create ? "파트너 등록" : "파트너 수정")
        .alert($store.scope(state: \.alert, action: \.alert))
    }

    private func toggle(_ list: [String], item: String) -> [String] {
        var updated = list
        if updated.contains(item) { updated.removeAll { $0 == item } }
        else { updated.append(item) }
        return updated
    }
}
