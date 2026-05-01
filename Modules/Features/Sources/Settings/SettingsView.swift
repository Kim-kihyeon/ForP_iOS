import SwiftUI
import ComposableArchitecture
import CoreSharedUI
import UIKit

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
                        wishlistSection
                        insightSection
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
        .tint(Brand.pink)
        .toolbarBackground(Brand.softPink, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear {
            store.send(.onAppear)
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(Brand.softPink)
            appearance.shadowColor = .clear
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        }
        .alert($store.scope(state: \.alert, action: \.alert))
    }

    // MARK: - Brand Header

    private var brandHeader: some View {
        ZStack {
            LinearGradient(
                colors: [Brand.pink.opacity(0.9), Brand.pink.opacity(0.55), Color(red: 1.0, green: 0.6, blue: 0.4).opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 200, height: 200)
                .blur(radius: 60)
                .offset(x: 80, y: -60)

            Circle()
                .fill(Color.white.opacity(0.07))
                .frame(width: 140, height: 140)
                .blur(radius: 40)
                .offset(x: -70, y: 50)

            HStack(spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ForP")
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                    Text("우리만의 데이트 코스")
                        .font(Typography.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.85))
                }
                Spacer()
                Image(systemName: "heart.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.white.opacity(0.20))
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
        }
        .frame(height: 130)
        .clipped()
    }

    // MARK: - Sections

    private var coupleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("COUPLE")

            FormCard {
                if store.isLoadingPartner {
                    HStack(spacing: Spacing.md) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Brand.softPink)
                            .frame(width: 36, height: 36)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("파트너 닉네임")
                                .font(Typography.body.weight(.semibold))
                            Text("카테고리 · 카테고리")
                                .font(Typography.caption2)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 2)
                    .redacted(reason: .placeholder)

                    Divider().padding(.leading, 52)

                    settingRow(icon: "heart.fill", iconColor: Brand.pink, title: "기념일 관리") {}
                        .redacted(reason: .placeholder)
                } else if let partner = store.partner {
                    Button {
                        store.send(.partnerTapped)
                    } label: {
                        HStack(spacing: Spacing.md) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(store.isConnected ? Brand.pink : Brand.softPink)
                                    .frame(width: 36, height: 36)
                                Image(systemName: store.isConnected ? "person.2.fill" : "person.fill")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(store.isConnected ? .white : Brand.pink)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(partner.nickname)
                                        .font(Typography.body.weight(.semibold))
                                        .foregroundStyle(.primary)
                                    if store.isConnected {
                                        Text("연동됨")
                                            .font(.system(size: 10, weight: .semibold))
                                            .foregroundStyle(Brand.pink)
                                            .padding(.horizontal, 6).padding(.vertical, 2)
                                            .background(Brand.softPink)
                                            .clipShape(Capsule())
                                    }
                                }
                                if !partner.preferredCategories.isEmpty {
                                    Text(partner.preferredCategories.prefix(3).joined(separator: " · "))
                                        .font(Typography.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 2)

                    Divider().padding(.leading, 52)

                    settingRow(icon: "heart.fill", iconColor: Brand.pink, title: "기념일 관리") {
                        store.send(.anniversaryTapped)
                    }

                    Divider().padding(.leading, 52)

                    settingRow(icon: "link", iconColor: Brand.iconBlue, title: "파트너 연동") {
                        store.send(.partnerConnectTapped)
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
                    settingRow(icon: "person.2.fill", iconColor: Brand.pink, title: "파트너 등록") {
                        store.send(.partnerTapped)
                    }

                    Divider().padding(.leading, 52)

                    settingRow(icon: "heart.fill", iconColor: Brand.pink, title: "기념일 관리") {
                        store.send(.anniversaryTapped)
                    }

                    Divider().padding(.leading, 52)

                    settingRow(icon: "link", iconColor: Brand.iconBlue, title: "파트너 연동") {
                        store.send(.partnerConnectTapped)
                    }
                }
            }
        }
    }

    private var wishlistSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("WISHLIST")

            FormCard {
                settingRow(
                    icon: "bookmark.fill",
                    iconColor: Brand.iconOrange,
                    title: "찜 목록 관리"
                ) {
                    store.send(.wishlistTapped)
                }

                Divider().padding(.leading, 52)

                settingRow(
                    icon: "checklist",
                    iconColor: Brand.iconGreen,
                    title: "기본 준비물 관리"
                ) {
                    store.send(.checklistTapped)
                }
            }
        }
    }

    private var insightSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("INSIGHT")

            FormCard {
                settingRow(
                    icon: "sparkles",
                    iconColor: Brand.pink,
                    title: "취향 지도"
                ) {
                    store.send(.tasteMapTapped)
                }
            }
        }
    }

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("ACCOUNT")

            FormCard {
                settingRow(
                    icon: "person.crop.circle",
                    iconColor: Brand.iconBlue,
                    title: "내 프로필 편집"
                ) {
                    store.send(.profileTapped)
                }

                Divider().padding(.leading, 52)

                settingRow(
                    icon: "rectangle.portrait.and.arrow.right",
                    iconColor: Color(.secondaryLabel),
                    title: "로그아웃"
                ) {
                    store.send(.logoutTapped)
                }

                Divider().padding(.leading, 52)

                settingRow(
                    icon: "trash.fill",
                    iconColor: .red,
                    title: "계정 삭제"
                ) {
                    store.send(.deleteAccountTapped)
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
