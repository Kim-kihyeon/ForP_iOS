import SwiftUI
import ComposableArchitecture
import CoreSharedUI
import Domain

public struct HomeView: View {
    @Bindable var store: StoreOf<HomeFeature>

    public init(store: StoreOf<HomeFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                List {
                    ForEach(store.recentCourses) { course in
                        Button(course.title) {
                            store.send(.courseSelected(course))
                        }
                    }
                }

                if store.isLoading {
                    LoadingView()
                }
            }
            .navigationTitle("ForP")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("코스 만들기") {
                        store.send(.generateCourseTapped)
                    }
                }
            }
        }
        .onAppear { store.send(.onAppear) }
    }
}
