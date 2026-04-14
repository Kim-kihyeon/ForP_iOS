import SwiftUI
import ComposableArchitecture
import CoreSharedUI

public struct OnboardingView: View {
    @Bindable var store: StoreOf<OnboardingFeature>

    private let categories = ["카페", "음식점", "공원", "문화", "쇼핑", "액티비티"]
    private let themes = ["조용한", "활동적인", "감성적인", "맛집 탐방", "자연"]

    public init(store: StoreOf<OnboardingFeature>) {
        self.store = store
    }

    public var body: some View {
        ZStack {
            Form {
                Section("선호 카테고리") {
                    FlowLayout(items: categories, selected: store.preferredCategories) {
                        store.send(.preferredCategoryToggled($0))
                    }
                }
                Section("비선호 카테고리") {
                    FlowLayout(items: categories, selected: store.dislikedCategories) {
                        store.send(.dislikedCategoryToggled($0))
                    }
                }
                Section("선호 테마") {
                    FlowLayout(items: themes, selected: store.preferredThemes) {
                        store.send(.themeToggled($0))
                    }
                }
                Section {
                    ForPButton("저장") { store.send(.saveTapped) }
                }
            }
            if store.isLoading { LoadingView() }
        }
        .navigationTitle("내 취향 설정")
    }
}
