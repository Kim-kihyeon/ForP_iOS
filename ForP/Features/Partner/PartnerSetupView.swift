import SwiftUI

struct PartnerSetupView: View {
    @State private var viewModel = PartnerSetupViewModel()

    var body: some View {
        VStack {
            Text("파트너 설정")
                .font(.title)
        }
        .padding()
    }
}

#Preview {
    PartnerSetupView()
}
