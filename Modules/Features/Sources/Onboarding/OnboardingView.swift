import SwiftUI
import ComposableArchitecture
import CoreSharedUI

public struct OnboardingView: View {
    @Bindable var store: StoreOf<OnboardingFeature>

    private let categories = ["카페", "음식점", "공원", "문화", "쇼핑", "액티비티", "전시/공연", "드라이브"]
    private let themes = ["조용한", "활동적인", "감성적인", "맛집 탐방", "자연", "도심", "이색적인"]

    public init(store: StoreOf<OnboardingFeature>) {
        self.store = store
    }

    public var body: some View {
        ZStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("어디서 데이트 하나요?")
                            .font(Typography.body)
                        TextField("예: 홍대, 강남, 성수동", text: $store.location)
                            .textFieldStyle(.plain)
                    }
                } header: {
                    Text("위치")
                }

                Section {
                    FlowLayout(
                        items: categories,
                        selected: store.preferredCategories
                    ) {
                        store.send(.preferredCategoryToggled($0))
                    }
                } header: {
                    Text("좋아하는 것")
                } footer: {
                    Text("데이트할 때 선호하는 장소 유형을 선택해주세요.")
                }

                Section {
                    FlowLayout(
                        items: categories,
                        selected: store.dislikedCategories
                    ) {
                        store.send(.dislikedCategoryToggled($0))
                    }
                } header: {
                    Text("싫어하는 것")
                } footer: {
                    Text("데이트할 때 피하고 싶은 장소 유형을 선택해주세요.")
                }

                Section {
                    FlowLayout(
                        items: themes,
                        selected: store.preferredThemes
                    ) {
                        store.send(.themeToggled($0))
                    }
                } header: {
                    Text("분위기")
                } footer: {
                    Text("선호하는 데이트 분위기를 선택해주세요.")
                }

                Section {
                    ForPButton("완료") {
                        store.send(.saveTapped)
                    }
                }
            }

            if store.isLoading {
                LoadingView()
            }
        }
        .navigationTitle("내 취향 설정")
        .navigationBarBackButtonHidden()
    }
}
