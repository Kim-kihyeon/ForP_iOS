import SwiftUI

public enum Colors {
    public static let primary = Color("Primary")
    public static let secondary = Color("Secondary")
    public static let background = Color("Background")
}

public enum Typography {
    public static let title = Font.system(.title, design: .rounded, weight: .bold)
    public static let body = Font.system(.body, design: .rounded)
    public static let caption = Font.system(.caption, design: .rounded)
}

public enum Spacing {
    public static let xs: CGFloat = 4
    public static let sm: CGFloat = 8
    public static let md: CGFloat = 16
    public static let lg: CGFloat = 24
    public static let xl: CGFloat = 32
}
