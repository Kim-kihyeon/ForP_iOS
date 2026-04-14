import SwiftUI

public struct ForPButton: View {
    let title: String
    let style: Style
    let action: () -> Void

    public enum Style {
        case primary, secondary, destructive
    }

    public init(_ title: String, style: Style = .primary, action: @escaping () -> Void) {
        self.title = title
        self.style = style
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(Typography.body)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
        }
        .buttonStyle(ForPButtonStyle(style: style))
    }
}

private struct ForPButtonStyle: ButtonStyle {
    let style: ForPButton.Style

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(backgroundColor)
            .foregroundStyle(foregroundColor)
            .cornerRadius(12)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }

    private var backgroundColor: Color {
        switch style {
        case .primary: return .accentColor
        case .secondary: return Color(.secondarySystemBackground)
        case .destructive: return .red
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary: return .white
        case .secondary: return .primary
        case .destructive: return .white
        }
    }
}
