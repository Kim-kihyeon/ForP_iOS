import SwiftUI

struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack {
            VStack {
                Text("홈")
                    .font(.title)

                NavigationLink("코스 만들기") {
                    CourseOptionView()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("ForP")
        }
    }
}

#Preview {
    HomeView()
        .environment(AppState())
}
