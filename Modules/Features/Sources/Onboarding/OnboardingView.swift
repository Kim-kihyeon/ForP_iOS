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
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("취향을 알려주세요")
                            .font(Typography.title)
                        Text("더 잘 맞는 코스를 추천해드릴게요")
                            .font(Typography.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.md)

                    onboardingSection("어디서 데이트 해요?", icon: "location.fill") {
                        TextField("예: 홍대, 강남, 성수동", text: $store.location)
                            .font(Typography.body)
                    }

                    onboardingSection("좋아하는 것", icon: "heart.fill") {
                        ChipGrid(items: categories, selected: store.preferredCategories) {
                            store.send(.preferredCategoryToggled($0))
                        }
                    }

                    onboardingSection("피하고 싶은 것", icon: "hand.raised.fill") {
                        ChipGrid(items: categories, selected: store.dislikedCategories) {
                            store.send(.dislikedCategoryToggled($0))
                        }
                    }

                    onboardingSection("선호 분위기", icon: "sparkles") {
                        ChipGrid(items: themes, selected: store.preferredThemes) {
                            store.send(.themeToggled($0))
                        }
                    }

                    ForPButton("시작하기") {
                        store.send(.saveTapped)
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.sm)
                    .padding(.bottom, Spacing.xl)
                }
            }

            if store.isLoading {
                LoadingView()
            }
        }
        .navigationBarBackButtonHidden()
    }

    @ViewBuilder
    private func onboardingSection<Content: View>(
        _ title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label(title, systemImage: icon)
                .font(Typography.caption.weight(.semibold))
                .foregroundStyle(Brand.pink)
            content()
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 1)
        .padding(.horizontal, Spacing.md)
    }
}
