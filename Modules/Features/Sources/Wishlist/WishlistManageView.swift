import SwiftUI
import ComposableArchitecture
import CoreSharedUI
import Domain

public struct WishlistManageView: View {
    let store: StoreOf<WishlistManageFeature>

    public init(store: StoreOf<WishlistManageFeature>) {
        self.store = store
    }

    public var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            if store.isLoading {
                ProgressView()
            } else if store.places.isEmpty {
                emptyView
            } else {
                List {
                    ForEach(store.places) { place in
                        placeRow(place)
                            .listRowBackground(Color(.secondarySystemGroupedBackground))
                    }
                    .onDelete { store.send(.delete($0)) }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("찜 목록")
        .navigationBarTitleDisplayMode(.inline)
        .tint(Brand.pink)
        .toolbarBackground(Brand.softPink, for: .navigationBar)
        .toolbar {
            EditButton()
                .tint(Brand.pink)
        }
        .onAppear { store.send(.onAppear) }
    }

    private func placeRow(_ place: WishlistPlace) -> some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Brand.softPink)
                    .frame(width: 36, height: 36)
                Image(systemName: categoryIcon(place.category))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Brand.pink)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(place.placeName ?? place.keyword)
                    .font(Typography.body.weight(.medium))
                Text(place.category)
                    .font(Typography.caption2)
                    .foregroundStyle(.secondary)
                if let address = place.address, !address.isEmpty {
                    Text(address)
                        .font(Typography.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "bookmark")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(.tertiary)
            Text("찜한 장소가 없어요")
                .font(Typography.body.weight(.medium))
                .foregroundStyle(.secondary)
            Text("코스 결과에서 장소를 찜해보세요")
                .font(Typography.caption)
                .foregroundStyle(.tertiary)
        }
    }

    private func categoryIcon(_ category: String) -> String {
        let c = category
        if c.contains("카페") || c.contains("커피") || c.contains("디저트") || c.contains("베이커리") { return "cup.and.saucer.fill" }
        if c.contains("레스토랑") || c.contains("식당") || c.contains("맛집") || c.contains("음식") || c.contains("한식") || c.contains("일식") || c.contains("중식") || c.contains("양식") || c.contains("이탈리안") || c.contains("브런치") || c.contains("분식") { return "fork.knife" }
        if c.contains("바") || c.contains("펍") || c.contains("주점") || c.contains("와인") || c.contains("칵테일") { return "wineglass.fill" }
        if c.contains("쇼핑") || c.contains("마켓") || c.contains("편집샵") { return "bag.fill" }
        if c.contains("공원") || c.contains("자연") || c.contains("숲") || c.contains("산") || c.contains("강") || c.contains("바다") || c.contains("해변") { return "leaf.fill" }
        if c.contains("문화") || c.contains("예술") || c.contains("박물관") || c.contains("미술관") || c.contains("갤러리") || c.contains("전시") { return "paintpalette.fill" }
        if c.contains("영화") || c.contains("공연") || c.contains("노래") || c.contains("게임") || c.contains("볼링") || c.contains("방탈출") { return "ticket.fill" }
        if c.contains("스파") || c.contains("목욕") || c.contains("찜질") { return "flame.fill" }
        if c.contains("액티비티") || c.contains("스포츠") || c.contains("클라이밍") || c.contains("운동") { return "figure.walk" }
        return "mappin.fill"
    }
}
