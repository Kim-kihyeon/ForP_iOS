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
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: Spacing.md) {
                        locationSection
                        placeCountSection
                        modeSection
                    }
                    .padding(Spacing.md)
                    .padding(.bottom, Spacing.sm)
                }

                VStack(spacing: 0) {
                    Divider()
                    ForPButton("코스 생성하기") {
                        store.send(.generateTapped)
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.md)
                    .padding(.bottom, Spacing.lg)
                }
                .background(Color(.systemBackground))
            }

            if store.isGenerating {
                LoadingView()
            }
        }
        .navigationTitle("코스 만들기")
        .navigationBarTitleDisplayMode(.inline)
        .alert("오류", isPresented: Binding(
            get: { store.errorMessage != nil },
            set: { if !$0 { store.send(.binding(.set(\.errorMessage, nil))) } }
        )) {
            Button("확인") { store.send(.binding(.set(\.errorMessage, nil))) }
        } message: {
            Text(store.errorMessage ?? "")
        }
    }

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label("어디서?", systemImage: "location.fill")
                .font(Typography.caption.weight(.semibold))
                .foregroundStyle(Brand.pink)

            TextField("예: 홍대, 강남, 성수동", text: $store.location)
                .font(Typography.body)
        }
        .sectionCard()
    }

    private var placeCountSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Label("몇 곳?", systemImage: "map.fill")
                .font(Typography.caption.weight(.semibold))
                .foregroundStyle(Brand.pink)

            HStack {
                Button {
                    if store.placeCount > 2 {
                        store.send(.binding(.set(\.placeCount, store.placeCount - 1)))
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(store.placeCount > 2 ? Brand.pink : Color(.tertiaryLabel))
                }

                Spacer()

                Text("\(store.placeCount)곳")
                    .font(.system(.title, design: .rounded, weight: .bold))

                Spacer()

                Button {
                    if store.placeCount < 6 {
                        store.send(.binding(.set(\.placeCount, store.placeCount + 1)))
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(store.placeCount < 6 ? Brand.pink : Color(.tertiaryLabel))
                }
            }
            .padding(.horizontal, Spacing.xl)
        }
        .sectionCard()
    }

    private var modeSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label("코스 타입", systemImage: "list.bullet")
                .font(Typography.caption.weight(.semibold))
                .foregroundStyle(Brand.pink)

            Picker("", selection: $store.mode) {
                Text("순서형").tag(CourseMode.ordered)
                Text("목록형").tag(CourseMode.list)
            }
            .pickerStyle(.segmented)
        }
        .sectionCard()
    }
}

private extension View {
    func sectionCard() -> some View {
        self
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 1)
    }
}
