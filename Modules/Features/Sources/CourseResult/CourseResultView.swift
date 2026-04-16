import SwiftUI
import ComposableArchitecture
import CoreSharedUI
import Domain

public struct CourseResultView: View {
    @Bindable var store: StoreOf<CourseResultFeature>

    private let placeColors: [Color] = [Brand.pink, Color(red: 0.4, green: 0.6, blue: 1.0), Color(red: 0.6, green: 0.4, blue: 1.0), Color(red: 0.2, green: 0.78, blue: 0.65), Color(red: 1.0, green: 0.6, blue: 0.2), Color(red: 1.0, green: 0.4, blue: 0.4)]

    public init(store: StoreOf<CourseResultFeature>) {
        self.store = store
    }

    public var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    if let outfit = store.course.outfitSuggestion, !outfit.isEmpty {
                        outfitCard(outfit)
                    }
                    ForEach(Array(store.course.places.enumerated()), id: \.element.order) { index, place in
                        placeCard(place, color: placeColors[index % placeColors.count])
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.md)
                .padding(.bottom, 32)
            }

            if store.isSaving || store.isDeleting {
                LoadingView()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 6) {
                    TextField("코스 제목", text: $store.course.title)
                        .font(Typography.headline)
                        .multilineTextAlignment(.center)
                        .fixedSize()
                    Image(systemName: "pencil")
                        .font(.caption2)
                        .foregroundStyle(Color(.tertiaryLabel))
                }
            }
            ToolbarItem(placement: .primaryAction) {
                if store.isSaved {
                    HStack(spacing: Spacing.sm) {
                        Button {
                            store.send(.likeTapped)
                        } label: {
                            Image(systemName: store.course.isLiked ? "heart.fill" : "heart")
                                .foregroundStyle(store.course.isLiked ? Brand.pink : .secondary)
                        }
                        Button(role: .destructive) {
                            store.send(.deleteTapped)
                        } label: {
                            Image(systemName: "trash")
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

    // MARK: - Outfit Card

    private func outfitCard(_ outfit: String) -> some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Brand.softPink)
                    .frame(width: 44, height: 44)
                Image(systemName: "tshirt.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Brand.pink)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("오늘의 옷차림")
                    .font(Typography.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(outfit)
                    .font(Typography.caption)
                    .foregroundStyle(.primary)
            }
            Spacer()
        }
        .padding(Spacing.md)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    // MARK: - Place Card

    private func placeCard(_ place: CoursePlace, color: Color) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .fill(color)
                        .frame(width: 36, height: 36)
                    Text("\(place.order)")
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(place.placeName ?? place.keyword)
                        .font(Typography.body.weight(.semibold))

                    Text(place.category)
                        .font(Typography.caption2)
                        .foregroundStyle(color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(color.opacity(0.1))
                        .clipShape(Capsule())

                    Text(place.reason)
                        .font(Typography.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)

                    if let menu = place.menu, !menu.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "fork.knife")
                            Text(menu)
                        }
                        .font(Typography.caption2)
                        .foregroundStyle(Brand.pink)
                        .padding(.top, 2)
                    }
                }

                Spacer()

                Button {
                    openKakaoMap(place: place)
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: "map.fill")
                            .font(.system(size: 16))
                        Text("지도")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(Brand.pink)
                    .padding(8)
                    .background(Brand.softPink)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(Spacing.md)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    // MARK: - Kakao Map

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
