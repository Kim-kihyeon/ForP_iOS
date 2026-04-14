import SwiftUI

struct OnboardingPreferenceView: View {
    @State private var viewModel = OnboardingPreferenceViewModel()

    var body: some View {
        VStack {
            Text("내 취향 설정")
                .font(.title)
        }
        .padding()
    }
}

#Preview {
    OnboardingPreferenceView()
}
