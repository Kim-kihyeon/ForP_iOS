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
            VStack(spacing: Spacing.xl) {
                Spacer()

                VStack(spacing: Spacing.xs) {
                    Text("ForP")
                        .font(Typography.title)
                    Text("P성향을 위한 데이트 코스")
                        .font(Typography.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(spacing: Spacing.md) {
                    ForPButton("카카오로 시작하기") {
                        store.send(.kakaoLoginTapped)
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
                    .frame(height: 50)
                    .cornerRadius(12)
                }
                .padding(.bottom, Spacing.xl)
            }
            .padding(.horizontal, Spacing.md)

            if store.isLoading {
                LoadingView()
            }
        }
        .alert($store.scope(state: \.alert, action: \.alert))
    }

    // MARK: - Apple Sign In Nonce

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
