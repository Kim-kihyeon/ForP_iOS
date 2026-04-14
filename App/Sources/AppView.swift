import SwiftUI
import ComposableArchitecture
import Features

struct AppView: View {
    @Bindable var store: StoreOf<AppFeature>

    var body: some View {
        switch store.route {
        case .login:
            LoginView(store: store.scope(state: \.login, action: \.login))
        case .onboarding:
            NavigationStack {
                OnboardingView(store: Store(initialState: OnboardingFeature.State()) {
                    OnboardingFeature()
                })
            }
        case .main:
            HomeView(store: store.scope(state: \.home, action: \.home))
        }
    }
}
