import SwiftUI
import ComposableArchitecture
import AuthenticationServices
import CoreSharedUI
import CryptoKit

public struct LoginView: View {
    @Bindable var store: StoreOf<LoginFeature>
    @State private var nonce = ""
    @State private var logoRing: CGFloat = 1.0
    @State private var heartFloat: CGFloat = 0

    public init(store: StoreOf<LoginFeature>) {
        self.store = store
    }

    public var body: some View {
        ZStack {
            LinearGradient(
                colors: [Brand.softPink, Brand.softPink.opacity(0.4), Color(.systemBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            Circle()
                .fill(Brand.pink.opacity(0.08))
                .frame(width: 300, height: 300)
                .blur(radius: 60)
                .offset(x: 120, y: -180)
                .ignoresSafeArea()

            Circle()
                .fill(Brand.softPink.opacity(0.5))
                .frame(width: 220, height: 220)
                .blur(radius: 50)
                .offset(x: -100, y: 200)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: Spacing.sm) {
                    ZStack {
                        Circle()
                            .fill(Brand.pink.opacity(0.1))
                            .frame(width: 136, height: 136)
                            .scaleEffect(logoRing)
                        Circle()
                            .fill(Brand.pink.opacity(0.2))
                            .frame(width: 116, height: 116)
                            .scaleEffect(logoRing)
                        Circle()
                            .fill(Brand.pink.opacity(0.35))
                            .frame(width: 96, height: 96)
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [Brand.softPink, Brand.pink.opacity(0.25)],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 44
                                    )
                                )
                                .frame(width: 88, height: 88)
                            Image(systemName: "heart.fill")
                                .font(.system(size: 38))
                                .foregroundStyle(Brand.pink)
                                .offset(y: heartFloat)
                        }
                    }
                    .padding(.bottom, Spacing.xs)

                    Text("ForP")
                        .font(.system(size: 42, weight: .bold, design: .rounded))

                    Text("P성향을 위한 데이트 코스")
                        .font(Typography.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(spacing: Spacing.sm) {
                    Button {
                        store.send(.kakaoLoginTapped)
                    } label: {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "bubble.fill")
                                .font(.system(size: 18))
                            Text("카카오로 시작하기")
                                .font(Typography.body.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Brand.kakaoYellow)
                        .foregroundStyle(Color(red: 0.11, green: 0.09, blue: 0.09))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .shadow(color: Brand.kakaoYellow.opacity(0.45), radius: 14, x: 0, y: 5)

                    SignInWithAppleButton(.signIn) { request in
                        let rawNonce = randomNonceString()
                        nonce = rawNonce
                        request.requestedScopes = [.fullName, .email]
                        request.nonce = sha256(rawNonce)
                    } onCompletion: { result in
                        switch result {
                        case .success(let auth):
                            guard
                                let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                                let tokenData = credential.identityToken,
                                let idToken = String(data: tokenData, encoding: .utf8)
                            else { return }
                            store.send(.appleLoginCompleted(idToken: idToken, nonce: nonce))
                        case .failure:
                            break
                        }
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 54)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.xxl)
            }

            if store.isLoading {
                LoadingView()
            }
        }
        .task {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                logoRing = 1.08
            }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                heartFloat = -5
            }
        }
        .alert($store.scope(state: \.alert, action: \.alert))
    }

    private func randomNonceString(length: Int = 32) -> String {
        var randomBytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        return randomBytes.map { String(format: "%02x", $0) }.joined()
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}
