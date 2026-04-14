import SwiftUI

struct LoginView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 16) {
            Text("ForP")
                .font(.largeTitle)
                .bold()

            Button("카카오 로그인") {
                // TODO: 카카오 OAuth 로그인
            }
            .buttonStyle(.borderedProminent)

            Button("Apple로 로그인") {
                // TODO: 애플 로그인
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}

#Preview {
    LoginView()
        .environment(AppState())
}
