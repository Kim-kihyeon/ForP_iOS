import SwiftUI
import ComposableArchitecture
import CoreSharedUI
import Domain

public struct CourseResultView: View {
    @Bindable var store: StoreOf<CourseResultFeature>

    private let badgeColors: [Color] = [.pink, .orange, .purple, .blue, .green, .red]

    public init(store: StoreOf<CourseResultFeature>) {
        self.store = store
    }

    public var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView {
                LazyVStack(spacing: Spacing.md) {
                    ForEach(store.course.places, id: \.order) { place in
                        placeCard(place)
                    }
                }
                .padding(Spacing.md)
            }

            if store.isSaving {
                LoadingView()
            }
        }
        .navigationTitle(store.course.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(store.isSaved ? "저장됨" : "저장") {
                    store.send(.saveTapped)
                }
                .font(Typography.body.weight(.semibold))
                .foregroundStyle(store.isSaved ? Color.secondary : Brand.pink)
                .disabled(store.isSaved)
            }
        }
    }

    private func placeCard(_ place: CoursePlace) -> some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(badgeColors[(place.order - 1) % badgeColors.count].opacity(0.15))
                    .frame(width: 44, height: 44)
                Text("\(place.order)")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(badgeColors[(place.order - 1) % badgeColors.count])
            }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(place.placeName ?? place.keyword)
                    .font(Typography.headline)

                Text(place.category)
                    .font(Typography.caption2)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, 3)
                    .background(Color(.tertiarySystemBackground))
                    .foregroundStyle(.secondary)
                    .clipShape(Capsule())

                Text(place.reason)
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }

            Spacer()
        }
        .padding(Spacing.md)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}
