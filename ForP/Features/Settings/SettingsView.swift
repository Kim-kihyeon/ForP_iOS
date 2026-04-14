import SwiftUI

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack {
            List {
                Section("내 취향") {
                    NavigationLink("취향 수정") {
                        OnboardingPreferenceView()
                    }
                }
                Section("파트너") {
                    Button("파트너 초기화", role: .destructive) {
                        // TODO: 파트너 초기화
                    }
                }
            }
            .navigationTitle("설정")
        }
    }
}

#Preview {
    SettingsView()
        .environment(AppState())
}
