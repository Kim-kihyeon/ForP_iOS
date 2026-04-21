import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Card Style

public struct CardStyle: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    public let cornerRadius: CGFloat
    public let shadowRadius: CGFloat

    public func body(content: Content) -> some View {
        content
            .background(Color(UIColor.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(
                color: colorScheme == .dark ? .clear : .black.opacity(0.06),
                radius: shadowRadius, x: 0, y: 2
            )
            .overlay {
                if colorScheme == .dark {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color(UIColor.separator), lineWidth: 1)
                }
            }
    }
}

extension View {
    public func cardStyle(cornerRadius: CGFloat = 16, shadowRadius: CGFloat = 8) -> some View {
        modifier(CardStyle(cornerRadius: cornerRadius, shadowRadius: shadowRadius))
    }
}

public enum Brand {
    public static let pink = Color(red: 1.0, green: 0.33, blue: 0.53)
    #if canImport(UIKit)
    public static let softPink = Color(UIColor { trait in
        switch trait.userInterfaceStyle {
        case .dark:
            return UIColor(red: 0.20, green: 0.07, blue: 0.11, alpha: 1)
        default:
            return UIColor(red: 1.0, green: 0.90, blue: 0.94, alpha: 1)
        }
    })
    #else
    public static let softPink = Color(red: 1.0, green: 0.90, blue: 0.94)
    #endif
    public static let kakaoYellow = Color(red: 0.996, green: 0.898, blue: 0.0)

    // Semantic icon colors
    public static let iconBlue   = Color(red: 0.4,  green: 0.6,  blue: 1.0)
    public static let iconGreen  = Color(red: 0.3,  green: 0.7,  blue: 0.5)
    public static let iconOrange = Color(red: 1.0,  green: 0.5,  blue: 0.3)
    public static let iconPurple = Color(red: 0.6,  green: 0.4,  blue: 1.0)
    public static let iconTeal   = Color(red: 0.2,  green: 0.78, blue: 0.65)
    public static let iconRed    = Color(red: 1.0,  green: 0.4,  blue: 0.4)
}

public enum Radius {
    public static let sm: CGFloat = 12
    public static let md: CGFloat = 16
    public static let lg: CGFloat = 20
    public static let xl: CGFloat = 24
}

public enum Shadow {
    public static let card  = (color: Color.black.opacity(0.06), radius: CGFloat(8),  y: CGFloat(2))
    public static let float = (color: Color.black.opacity(0.10), radius: CGFloat(16), y: CGFloat(6))
    public static let button = (color: CGFloat(0.3), radius: CGFloat(10), y: CGFloat(4)) // opacity multiplied with Brand.pink
}

public enum Typography {
    public static let largeTitle = Font.system(.largeTitle, design: .rounded, weight: .bold)
    public static let title = Font.system(.title, design: .rounded, weight: .bold)
    public static let title2 = Font.system(.title2, design: .rounded, weight: .semibold)
    public static let headline = Font.system(.headline, design: .rounded, weight: .semibold)
    public static let body = Font.system(.body, design: .rounded)
    public static let caption = Font.system(.caption, design: .rounded)
    public static let caption2 = Font.system(.caption2, design: .rounded)
}

public enum Spacing {
    public static let xs: CGFloat = 4
    public static let sm: CGFloat = 8
    public static let md: CGFloat = 16
    public static let lg: CGFloat = 24
    public static let xl: CGFloat = 32
    public static let xxl: CGFloat = 48
}

// MARK: - Keyboard Dismiss

#if canImport(UIKit)
public extension View {
    func hideKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }

    func disableSwipeBack() -> some View {
        self.background(SwipeBackDisabler())
    }
}

private struct SwipeBackDisabler: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }
    func updateUIViewController(_ vc: UIViewController, context: Context) {
        DispatchQueue.main.async {
            vc.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        }
    }
}
#endif
