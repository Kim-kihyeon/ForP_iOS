import SwiftUI

public struct FormCard<Content: View>: View {
    @ViewBuilder public let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            content
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

public struct SectionHeader: View {
    let title: String

    public init(_ title: String) {
        self.title = title
    }

    public var body: some View {
        Text(title)
            .font(.system(.caption2, design: .default, weight: .semibold))
            .foregroundStyle(.secondary)
            .padding(.leading, 4)
    }
}

public struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: (() -> Void)?
    let actionTitle: String

    public init(
        icon: String,
        title: String,
        subtitle: String,
        actionTitle: String = "",
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(.quaternary)
                .padding(.bottom, Spacing.xs)

            VStack(spacing: Spacing.xs) {
                Text(title)
                    .font(Typography.headline)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let action, !actionTitle.isEmpty {
                Button(actionTitle, action: action)
                    .font(Typography.caption.weight(.semibold))
                    .foregroundStyle(Brand.pink)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(Brand.softPink)
                    .clipShape(Capsule())
                    .padding(.top, Spacing.xs)
            }
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity)
    }
}
