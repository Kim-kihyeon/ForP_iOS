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
                    if let outfit = store.course.outfitSuggestion, !outfit.isEmpty {
                        outfitCard(outfit)
                    }
                    ForEach(store.course.places, id: \.order) { place in
                        placeCard(place)
                    }
                }
                .padding(Spacing.md)
            }

            if store.isSaving || store.isDeleting {
                LoadingView()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 4) {
                    TextField("코스 제목", text: $store.course.title)
                        .font(Typography.headline)
                        .multilineTextAlignment(.center)
                    Image(systemName: "pencil")
                        .font(Typography.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if store.isSaved {
                    HStack(spacing: Spacing.sm) {
                        Button {
                            store.send(.likeTapped)
                        } label: {
                            Image(systemName: store.course.isLiked ? "heart.fill" : "heart")
                                .foregroundStyle(store.course.isLiked ? Brand.pink : .secondary)
                                .font(Typography.body.weight(.semibold))
                        }
                        Button(role: .destructive) {
                            store.send(.deleteTapped)
                        } label: {
                            Image(systemName: "trash")
                                .font(Typography.body.weight(.semibold))
                        }
                    }
                } else {
                    Button("저장") {
                        store.send(.saveTapped)
                    }
                    .font(Typography.body.weight(.semibold))
                    .foregroundStyle(Brand.pink)
                }
            }
        }
        .alert($store.scope(state: \.alert, action: \.alert))
    }

    private func outfitCard(_ outfit: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "tshirt.fill")
                .font(.title3)
                .foregroundStyle(Brand.pink)
            VStack(alignment: .leading, spacing: 2) {
                Text("오늘의 옷차림")
                    .font(Typography.caption2)
                    .foregroundStyle(.secondary)
                Text(outfit)
                    .font(Typography.caption)
            }
            Spacer()
        }
        .padding(Spacing.md)
        .background(Brand.softPink)
        .clipShape(RoundedRectangle(cornerRadius: 16))
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
                    .foregroundStyle(.secondary)

                Text(place.reason)
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)

                if let menu = place.menu, !menu.isEmpty {
                    Label(menu, systemImage: "fork.knife")
                        .font(Typography.caption2)
                        .foregroundStyle(Brand.pink)
                        .padding(.top, 2)
                }
            }

            Spacer()

            Button {
                openKakaoMap(place: place)
            } label: {
                Image(systemName: "map.fill")
                    .font(Typography.body)
                    .foregroundStyle(Brand.pink)
            }
        }
        .padding(Spacing.md)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    private func openKakaoMap(place: CoursePlace) {
        let placeName = place.placeName ?? place.keyword
        guard let encoded = placeName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }

        let appURLString: String
        if let lat = place.latitude, let lon = place.longitude {
            appURLString = "kakaomap://search?q=\(encoded)&p=\(lat),\(lon)"
        } else {
            appURLString = "kakaomap://search?q=\(encoded)"
        }

        guard let appURL = URL(string: appURLString) else { return }
        UIApplication.shared.open(appURL) { success in
            guard !success else { return }
            guard let encoded2 = placeName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
                  let webURL = URL(string: "https://map.kakao.com/link/search/\(encoded2)") else { return }
            UIApplication.shared.open(webURL)
        }
    }
}
