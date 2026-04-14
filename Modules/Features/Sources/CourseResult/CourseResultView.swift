import SwiftUI
import ComposableArchitecture
import CoreSharedUI
import Domain

public struct CourseResultView: View {
    @Bindable var store: StoreOf<CourseResultFeature>

    public init(store: StoreOf<CourseResultFeature>) {
        self.store = store
    }

    public var body: some View {
        ZStack {
            Group {
                switch store.course.mode {
                case .ordered:
                    orderedList
                case .list:
                    cardList
                }
            }

            if store.isSaving {
                LoadingView()
            }
        }
        .navigationTitle(store.course.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(store.isSaved ? "저장됨" : "저장") {
                    store.send(.saveTapped)
                }
                .disabled(store.isSaved)
            }
        }
    }

    private var orderedList: some View {
        List(store.course.places, id: \.order) { place in
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("\(place.order). \(place.placeName ?? place.keyword)")
                    .font(Typography.body)
                Text(place.category).font(.caption).foregroundStyle(.secondary)
                Text(place.reason).font(.caption2)
            }
        }
    }

    private var cardList: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.md) {
                ForEach(store.course.places, id: \.order) { place in
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(place.placeName ?? place.keyword).font(Typography.body)
                        Text(place.category).font(.caption).foregroundStyle(.secondary)
                        Text(place.reason).font(.caption2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Spacing.md)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(Spacing.md)
        }
    }
}
