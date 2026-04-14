import SwiftUI
import ComposableArchitecture
import CoreSharedUI

public struct LoginView: View {
    @Bindable var store: StoreOf<LoginFeature>

    public init(store: StoreOf<LoginFeature>) {
        self.store = store
    }

    public var body: some View {
        ZStack {
            VStack(spacing: Spacing.lg) {
                Text("ForP")
                    .font(Typography.title)

                Spacer()

                ForPButton("카카오 로그인") {
                    store.send(.kakaoLoginTapped)
                }

                ForPButton("Apple로 로그인", style: .secondary) {
                    store.send(.appleLoginTapped)
                }
            }
            .padding(Spacing.md)

            if store.isLoading {
                LoadingView()
            }
        }
        .alert($store.scope(state: \.alert, action: \.alert))
    }
}
