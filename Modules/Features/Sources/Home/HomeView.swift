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
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            ZStack {
                Group {
                    if store.recentCourses.isEmpty && !store.isLoading {
                        emptyView
                    } else {
                        courseList
                    }
                }

                if store.isLoading {
                    LoadingView()
                }
            }
            .navigationTitle("ForP")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        store.send(.generateCourseTapped)
                    } label: {
                        Label("코스 만들기", systemImage: "plus")
                    }
                }
            }
        } destination: { store in
            switch store.case {
            case .courseGenerate(let store):
                CourseGenerateView(store: store)
            case .courseResult(let store):
                CourseResultView(store: store)
            }
        }
        .onAppear { store.send(.onAppear) }
    }

    private var emptyView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "map")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("아직 만든 코스가 없어요")
                .font(Typography.body)
                .foregroundStyle(.secondary)
            ForPButton("첫 코스 만들기") {
                store.send(.generateCourseTapped)
            }
            .padding(.horizontal, Spacing.xl)
        }
    }

    private var courseList: some View {
        List(store.recentCourses) { course in
            Button {
                store.send(.courseSelected(course))
            } label: {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(course.title)
                        .font(Typography.body)
                        .foregroundStyle(.primary)
                    Text(course.places.map { $0.placeName ?? $0.keyword }.joined(separator: " → "))
                        .font(Typography.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .padding(.vertical, Spacing.xs)
            }
        }
    }
}
