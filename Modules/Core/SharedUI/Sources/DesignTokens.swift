import SwiftUI

public enum Brand {
    public static let pink = Color(red: 1.0, green: 0.33, blue: 0.53)
    public static let softPink = Color(red: 1.0, green: 0.90, blue: 0.94)
    public static let kakaoYellow = Color(red: 0.996, green: 0.898, blue: 0.0)
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
