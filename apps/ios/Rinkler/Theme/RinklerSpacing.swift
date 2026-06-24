import Foundation

enum RinklerSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48

    // Icon sizes
    static let appIconSmall: CGFloat = 56
    static let appIconMedium: CGFloat = 64
    static let appIconLarge: CGFloat = 72

    // Dial
    static let dialRadius: CGFloat = 120
    static let dialCenterIcon: CGFloat = 80
    static let dialOptionSize: CGFloat = 48

    // Page dot
    static let dotSize: CGFloat = 8
    static let dotSpacing: CGFloat = 8

    // Button
    static let buttonHeight: CGFloat = 56
    static let buttonCornerRadius: CGFloat = 28
    static let buttonHorizontalPadding: CGFloat = 60

    // Profile avatar
    static let avatarSize: CGFloat = 36

    // MARK: - Control heights
    //
    // Button heights were scattered across 34/36/38/42/48/50/52/54/56/58/66.
    // These three tokens standardize them. Anything smaller than `minHitTarget`
    // must still expand its tappable area to 44pt via padding/contentShape.

    /// Primary call-to-action height (Start protection, Start session…).
    static let primaryControl: CGFloat = 56
    /// Secondary actions / inline buttons.
    static let secondaryControl: CGFloat = 48
    /// Compact pill controls (Start/Stop, Grant). Pad the hit target to 44pt.
    static let compactControl: CGFloat = 36
    /// Apple's minimum comfortable tap target.
    static let minHitTarget: CGFloat = 44

    // MARK: - Corner radii
    /// Standard card radius.
    static let cardRadius: CGFloat = 20
    /// Standard control / button radius.
    static let controlRadius: CGFloat = 16
}
