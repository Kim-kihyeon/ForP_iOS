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
                        notificationSection
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
                colors: [
                    Color(red: 0.90, green: 0.15, blue: 0.35),
                    Brand.pink,
                    Color(red: 1.0, green: 0.58, blue: 0.38)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 200, height: 200)
                .blur(radius: 50)
                .offset(x: 100, y: -70)

            Circle()
                .fill(Color.white.opacity(0.07))
                .frame(width: 140, height: 140)
                .blur(radius: 36)
                .offset(x: -60, y: 60)

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
                    .foregroundStyle(.white.opacity(0.35))
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
            sectionLabel("커플")

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
            sectionLabel("내 기록")

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

                Divider().padding(.leading, 52)

                settingRow(
                    icon: "map.fill",
                    iconColor: Brand.iconBlue,
                    title: "취향 지도"
                ) {
                    store.send(.tasteMapTapped)
                }
            }
        }
    }

    private var notificationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("알림")

            FormCard {
                notificationToggleRow(
                    icon: "bell.fill",
                    iconColor: Brand.pink,
                    title: "푸쉬 알림",
                    subtitle: store.notificationPermissionStatus == .denied ? "iPhone 설정에서 알림 권한이 꺼져 있어요" : "앱 알림 전체 수신",
                    isOn: effectivePushEnabled
                ) { enabled in
                    store.send(.pushNotificationToggled(enabled))
                }

                Divider().padding(.leading, 52)

                notificationToggleRow(
                    icon: "calendar.badge.clock",
                    iconColor: Brand.iconBlue,
                    title: "코스 당일 알림",
                    subtitle: "저장한 코스 날짜 오전 알림",
                    isOn: effectivePushEnabled && store.notificationSettings.courseReminderEnabled,
                    disabled: !effectivePushEnabled
                ) { enabled in
                    store.send(.courseReminderToggled(enabled))
                }

                Divider().padding(.leading, 52)

                notificationToggleRow(
                    icon: "heart.text.square.fill",
                    iconColor: Brand.iconOrange,
                    title: "기념일 알림",
                    subtitle: "30일 전, 7일 전, 당일 알림",
                    isOn: effectivePushEnabled && store.notificationSettings.anniversaryEnabled,
                    disabled: !effectivePushEnabled
                ) { enabled in
                    store.send(.anniversaryNotificationToggled(enabled))
                }

                Divider().padding(.leading, 52)

                notificationToggleRow(
                    icon: "person.2.wave.2.fill",
                    iconColor: Brand.iconGreen,
                    title: "파트너 알림",
                    subtitle: "파트너가 코스를 공유했을 때",
                    isOn: effectivePushEnabled && store.notificationSettings.partnerEnabled,
                    disabled: !effectivePushEnabled
                ) { enabled in
                    store.send(.partnerNotificationToggled(enabled))
                }
            }
        }
    }

    private var effectivePushEnabled: Bool {
        store.notificationSettings.pushEnabled && store.notificationPermissionStatus != .denied
    }

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("계정")

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
            .font(.system(.caption2, design: .rounded, weight: .semibold))
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

    private func notificationToggleRow(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        isOn: Bool,
        disabled: Bool = false,
        onChange: @escaping (Bool) -> Void
    ) -> some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconColor.opacity(disabled ? 0.07 : 0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(disabled ? Color(.tertiaryLabel) : iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Typography.body)
                    .foregroundStyle(disabled ? .secondary : .primary)
                Text(subtitle)
                    .font(Typography.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { isOn },
                set: { onChange($0) }
            ))
            .labelsHidden()
            .tint(Brand.pink)
            .disabled(disabled)
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
    }
}
