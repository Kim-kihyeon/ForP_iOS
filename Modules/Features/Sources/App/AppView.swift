import SwiftUI
import ComposableArchitecture

public struct AppView: View {
    @Bindable public var store: StoreOf<AppFeature>

    public init(store: StoreOf<AppFeature>) {
        self.store = store
    }

    public var body: some View {
        switch store.route {
        case .splash:
            Color(.systemBackground).ignoresSafeArea()

        case .login:
            LoginView(store: store.scope(state: \.login, action: \.login))

        case .onboarding:
            NavigationStack {
                OnboardingView(store: store.scope(state: \.onboarding, action: \.onboarding))
            }

        case .main:
            HomeView(store: store.scope(state: \.home, action: \.home))
        }
    }
}
