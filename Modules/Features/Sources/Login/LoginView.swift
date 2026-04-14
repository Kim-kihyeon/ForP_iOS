import SwiftUI
import ComposableArchitecture
import AuthenticationServices
import CoreSharedUI
import CryptoKit

public struct LoginView: View {
    @Bindable var store: StoreOf<LoginFeature>
    @State private var nonce = ""

    public init(store: StoreOf<LoginFeature>) {
        self.store = store
    }

    public var body: some View {
        ZStack {
            LinearGradient(
                colors: [Brand.softPink, Color(.systemBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: Spacing.sm) {
                    ZStack {
                        Circle()
                            .fill(Brand.softPink)
                            .frame(width: 96, height: 96)
                        Image(systemName: "heart.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(Brand.pink)
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
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.xxl)
            }

            if store.isLoading {
                LoadingView()
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
