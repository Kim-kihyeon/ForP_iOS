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

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    brandHeader

                    VStack(spacing: 12) {
                        coupleSection
                        accountSection
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.md)
                    .padding(.bottom, Spacing.lg)
                }
            }

            if store.isLoading { LoadingView() }
        }
        .navigationTitle("설정")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Brand.pink, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear { store.send(.onAppear) }
        .alert($store.scope(state: \.alert, action: \.alert))
    }

    // MARK: - Brand Header

    private var brandHeader: some View {
        ZStack {
            LinearGradient(
                colors: [Brand.pink.opacity(0.85), Brand.pink.opacity(0.55)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            HStack(spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ForP")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                    Text("우리만의 데이트 코스")
                        .font(Typography.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.85))
                }
                Spacer()
                Image(systemName: "heart.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
        }
        .frame(height: 90)
    }

    // MARK: - Sections

    private var coupleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("COUPLE")

            SettingsFormCard {
                settingRow(icon: "person.2.fill", iconColor: Brand.pink, title: store.hasPartner ? "파트너 수정" : "파트너 등록") {
                    store.send(.partnerTapped)
                }

                if store.hasPartner {
                    Divider().padding(.leading, 52)

                    settingRow(icon: "heart.fill", iconColor: Brand.pink, title: "기념일 관리") {
                        store.send(.anniversaryTapped)
                    }

                    Divider().padding(.leading, 52)

                    Button {
                        store.send(.resetPartnerTapped)
                    } label: {
                        HStack(spacing: Spacing.md) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.red.opacity(0.1))
                                    .frame(width: 36, height: 36)
                                Image(systemName: "trash.fill")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(.red)
                            }
                            Text("파트너 초기화")
                                .font(Typography.body)
                                .foregroundStyle(.red)
                            Spacer()
                        }
                        .padding(.vertical, 2)
                    }
                    .buttonStyle(.plain)
                } else {
                    Divider().padding(.leading, 52)

                    settingRow(icon: "heart.fill", iconColor: Brand.pink, title: "기념일 관리") {
                        store.send(.anniversaryTapped)
                    }
                }
            }
        }
    }

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("ACCOUNT")

            SettingsFormCard {
                settingRow(
                    icon: "rectangle.portrait.and.arrow.right",
                    iconColor: Color(.secondaryLabel),
                    title: "로그아웃"
                ) {
                    store.send(.logoutTapped)
                }
            }
        }
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(.caption2, design: .default, weight: .semibold))
            .foregroundStyle(.secondary)
            .padding(.leading, 4)
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
                    RoundedRectangle(cornerRadius: 10)
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .medium))
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
            .padding(.vertical, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct SettingsFormCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            content
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}
