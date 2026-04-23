import SwiftUI
import ComposableArchitecture
import AuthenticationServices
import CoreSharedUI
import CryptoKit
import UIKit

public struct LoginView: View {
    @Bindable var store: StoreOf<LoginFeature>
    @State private var logoRing: CGFloat = 1.0
    @State private var heartFloat: CGFloat = 0
    @State private var coordinator = AppleSignInCoordinator()
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("lastLoginMethod") private var lastLoginMethod = ""

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
                    loginButton(isRecent: lastLoginMethod == "kakao") {
                        store.send(.kakaoLoginTapped)
                        lastLoginMethod = "kakao"
                    } label: {
                        HStack(spacing: Spacing.sm) {
                            if let uiImage = kakaoIconImage {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 22, height: 22)
                            }
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

                    loginButton(isRecent: lastLoginMethod == "apple") {
                        performAppleSignIn()
                    } label: {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "apple.logo")
                                .font(.system(size: 18, weight: .medium))
                            Text("Apple로 계속하기")
                                .font(Typography.body.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(colorScheme == .dark ? Color.white : Color.black)
                        .foregroundStyle(colorScheme == .dark ? Color.black : Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
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
        .onAppear {
            coordinator.onCompleted = { idToken, nonce in
                lastLoginMethod = "apple"
                store.send(.appleLoginCompleted(idToken: idToken, nonce: nonce))
            }
        }
    }

    // MARK: - Private

    @ViewBuilder
    private func loginButton<Label: View>(
        isRecent: Bool,
        action: @escaping () -> Void,
        @ViewBuilder label: () -> Label
    ) -> some View {
        ZStack(alignment: .topTrailing) {
            Button(action: action, label: label)
                .buttonStyle(LoginPressStyle())
            if isRecent {
                Text("최근 로그인")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Brand.pink)
                    .clipShape(Capsule())
                    .offset(x: -8, y: -8)
                    .allowsHitTesting(false)
            }
        }
    }

    private func performAppleSignIn() {
        let rawNonce = randomNonceString()
        coordinator.performSignIn(rawNonce: rawNonce, sha256Nonce: sha256(rawNonce))
    }

    private var kakaoIconImage: UIImage? {
        guard
            let bundlePath = Bundle.main.path(forResource: "KakaoOpenSDK_KakaoSDKUser", ofType: "bundle"),
            let bundle = Bundle(path: bundlePath)
        else { return nil }
        return UIImage(named: "chat", in: bundle, compatibleWith: nil)
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

// MARK: - Button Style

private struct LoginPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.65 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Apple Sign In Coordinator

@MainActor
private class AppleSignInCoordinator: NSObject,
    ASAuthorizationControllerDelegate,
    ASAuthorizationControllerPresentationContextProviding
{
    var onCompleted: ((String, String) -> Void)?
    private var activeController: ASAuthorizationController?
    private var currentNonce = ""

    func performSignIn(rawNonce: String, sha256Nonce: String) {
        currentNonce = rawNonce
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256Nonce

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        activeController = controller
        controller.performRequests()
    }

    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first(where: { $0.isKeyWindow }) ?? UIWindow()
        }
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        defer { activeController = nil }
        guard
            let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let tokenData = credential.identityToken,
            let idToken = String(data: tokenData, encoding: .utf8)
        else { return }
        onCompleted?(idToken, currentNonce)
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        activeController = nil
    }
}
