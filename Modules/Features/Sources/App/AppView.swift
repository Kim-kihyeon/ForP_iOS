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
    @State private var glowOpacity: Double = 0.2
    @State private var dotOffsets: [CGFloat] = [0, 0, 0]

    var body: some View {
        ZStack {
            // 배경 그라데이션
            LinearGradient(
                colors: [
                    Color(red: 0.90, green: 0.15, blue: 0.35),
                    Brand.pink,
                    Color(red: 1.0, green: 0.58, blue: 0.38)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // 배경 글로우 블롭
            Circle()
                .fill(Color.white.opacity(glowOpacity))
                .frame(width: 320)
                .blur(radius: 80)
                .offset(x: 80, y: -180)

            Circle()
                .fill(Color.white.opacity(glowOpacity * 0.6))
                .frame(width: 240)
                .blur(radius: 60)
                .offset(x: -100, y: 200)

            VStack(spacing: 28) {
                // 텍스트
                VStack(spacing: 10) {
                    Text("ForP")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text("둘의 취향을 바탕으로\n데이트 코스를 추천해요")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)

                // 바운싱 도트
                HStack(spacing: 9) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(Color.white.opacity(0.85))
                            .frame(width: 7, height: 7)
                            .offset(y: dotOffsets[i])
                    }
                }
                .padding(.top, 4)
                .opacity(appeared ? 1 : 0)
            }
            .padding(.horizontal, Spacing.xl)
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.72)) {
                appeared = true
            }
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                glowOpacity = 0.08
            }
            for i in 0..<3 {
                withAnimation(
                    .easeInOut(duration: 0.55)
                        .repeatForever(autoreverses: true)
                        .delay(0.5 + Double(i) * 0.18)
                ) {
                    dotOffsets[i] = -7
                }
            }
        }
    }
}
