import SwiftUI
import ComposableArchitecture
import CoreSharedUI

public struct AppView: View {
    @Bindable public var store: StoreOf<AppFeature>

    public init(store: StoreOf<AppFeature>) {
        self.store = store
    }

    public var body: some View {
        switch store.route {
        case .splash:
            SplashView()

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

private struct SplashView: View {
    @State private var appeared = false
    @State private var pulse = false

    var body: some View {
        ZStack {
            Color(.systemBackground)
            .ignoresSafeArea()

            VStack(spacing: 22) {
                ZStack {
                    Circle()
                        .fill(Brand.softPink)
                        .frame(width: 164, height: 164)
                        .scaleEffect(pulse ? 1.06 : 0.96)
                        .opacity(pulse ? 0.62 : 0.95)

                    Circle()
                        .stroke(Brand.pink.opacity(0.18), lineWidth: 1)
                        .frame(width: 142, height: 142)

                    Image("SplashAppIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 108, height: 108)
                        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                        .shadow(color: Brand.pink.opacity(0.20), radius: 24, x: 0, y: 10)
                }
                .scaleEffect(appeared ? 1 : 0.92)
                .opacity(appeared ? 1 : 0)

                VStack(spacing: 8) {
                    Text("ForP")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text("취향에 맞는 데이트 코스를 준비하고 있어요")
                        .font(Typography.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 8)

                HStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(Brand.pink.opacity(0.85))
                            .frame(width: 6, height: 6)
                            .scaleEffect(pulse ? 1.0 : 0.72)
                            .animation(
                                .easeInOut(duration: 0.7)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.14),
                                value: pulse
                            )
                    }
                }
                .padding(.top, 8)
                    .opacity(appeared ? 1 : 0)
            }
            .padding(.horizontal, Spacing.xl)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.45)) {
                appeared = true
            }
            pulse = true
        }
    }
}
