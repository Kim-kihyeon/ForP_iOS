import SwiftUI
import ComposableArchitecture
import CoreSharedUI
import Domain

public struct CourseGenerateView: View {
    @Bindable var store: StoreOf<CourseGenerateFeature>

    public init(store: StoreOf<CourseGenerateFeature>) {
        self.store = store
    }

    public var body: some View {
        ZStack {
            Form {
                Section("위치") {
                    TextField("예: 홍대, 강남", text: $store.location)
                }
                Section("장소 수") {
                    Stepper("\(store.placeCount)곳", value: $store.placeCount, in: 2...6)
                }
                Section("코스 모드") {
                    Picker("모드", selection: $store.mode) {
                        Text("순서형").tag(CourseMode.ordered)
                        Text("목록형").tag(CourseMode.list)
                    }
                    .pickerStyle(.segmented)
                }
                Section {
                    ForPButton("코스 생성") {
                        store.send(.generateTapped)
                    }
                }
            }

            if store.isGenerating {
                LoadingView()
            }
        }
        .navigationTitle("코스 만들기")
        .alert("오류", isPresented: Binding(
            get: { store.errorMessage != nil },
            set: { if !$0 { store.send(.binding(.set(\.errorMessage, nil))) } }
        )) {
            Button("확인") { store.send(.binding(.set(\.errorMessage, nil))) }
        } message: {
            Text(store.errorMessage ?? "")
        }
    }
}
