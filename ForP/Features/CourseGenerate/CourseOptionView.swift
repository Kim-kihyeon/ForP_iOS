import SwiftUI

struct CourseOptionView: View {
    @State private var viewModel = CourseOptionViewModel()

    var body: some View {
        VStack {
            Text("코스 옵션")
                .font(.title)
        }
        .padding()
        .navigationTitle("코스 만들기")
    }
}

#Preview {
    NavigationStack {
        CourseOptionView()
    }
}
