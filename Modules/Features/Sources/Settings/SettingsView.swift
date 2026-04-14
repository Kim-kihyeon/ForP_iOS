import SwiftUI
import ComposableArchitecture
import CoreSharedUI

public struct SettingsView: View {
    @Bindable var store: StoreOf<SettingsFeature>

    public init(store: StoreOf<SettingsFeature>) {
        self.store = store
    }

    public var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView {
                VStack(spacing: Spacing.md) {
                    settingRow(
                        icon: "person.2.fill",
                        iconColor: Brand.pink,
                        title: store.hasPartner ? "파트너 수정" : "파트너 등록"
                    ) {
                        store.send(.partnerTapped)
                    }

                    if store.hasPartner {
                        settingRow(
                            icon: "trash.fill",
                            iconColor: .red,
                            title: "파트너 초기화"
                        ) {
                            store.send(.resetPartnerTapped)
                        }
                    }

                    Divider()
                        .padding(.horizontal, Spacing.md)

                    settingRow(
                        icon: "rectangle.portrait.and.arrow.right",
                        iconColor: .secondary,
                        title: "로그아웃"
                    ) {
                        store.send(.logoutTapped)
                    }
                }
                .padding(.top, Spacing.md)
            }

            if store.isLoading {
                LoadingView()
            }
        }
        .navigationTitle("설정")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { store.send(.onAppear) }
        .alert($store.scope(state: \.alert, action: \.alert))
    }

    private func settingRow(
        icon: String,
        iconColor: Color,
        title: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundStyle(iconColor)
                }

                Text(title)
                    .font(Typography.body)
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(Spacing.md)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Spacing.md)
    }
}
