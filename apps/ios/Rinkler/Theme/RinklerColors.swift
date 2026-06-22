import SwiftUI

/// Rinkler "Living Sky" palette.
///
/// The identity is a deep night sky that *clears toward dawn* as the user's
/// focus grows. Most of the UI is calm midnight-indigo with a single luminous
/// aurora accent. Legacy token names (`skyBlue`, `white60`, ...) are preserved
/// so existing screens keep compiling while the new tokens drive the redesign.
enum RinklerColors {
    // MARK: - Aurora accent (the one signature color)

    /// Mint-cyan end of the aurora.
    static let auroraCyan = Color(red: 0.36, green: 0.88, blue: 0.78)   // #5BE1C6
    /// Periwinkle-violet end of the aurora.
    static let auroraViolet = Color(red: 0.54, green: 0.49, blue: 1.0)  // #8A7CFF

    /// The accent gradient. Used sparingly: hero ring, primary action, streak.
    static let aurora = LinearGradient(
        colors: [auroraCyan, auroraViolet],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Single flat accent for places a gradient is too busy (charts, small dots).
    /// Re-points the legacy `skyBlue` token so un-rebuilt screens adopt the new
    /// look automatically.
    static let skyBlue = Color(red: 0.50, green: 0.52, blue: 1.0)       // #7F85FF
    static let navyBlue = skyBlue

    // MARK: - Night sky stops (deep -> horizon)

    static let nightTop = Color(red: 0.027, green: 0.043, blue: 0.118)  // #070B1E
    static let nightMid = Color(red: 0.071, green: 0.102, blue: 0.227)  // #121A3A
    static let nightHorizon = Color(red: 0.118, green: 0.165, blue: 0.341) // #1E2A57

    /// Warm dawn glow that rises from the horizon as focus clarity increases.
    static let dawnGlow = Color(red: 0.96, green: 0.79, blue: 0.66)     // #F5C9A8
    static let dawnViolet = Color(red: 0.42, green: 0.36, blue: 0.62)   // #6B5C9E

    // MARK: - Text & surface

    static let white = Color.white
    static let white30 = Color.white.opacity(0.30)
    static let white40 = Color.white.opacity(0.40)
    static let white60 = Color.white.opacity(0.62)

    /// Frosted card fill + hairline stroke.
    static let surface = Color.white.opacity(0.06)
    static let surfaceRaised = Color.white.opacity(0.10)
    static let hairline = Color.white.opacity(0.12)

    // MARK: - Legacy gradient (kept for compatibility)

    static let skyGradient = LinearGradient(
        colors: [nightHorizon, nightMid, nightTop],
        startPoint: .top,
        endPoint: .bottom
    )

    // MARK: - Living gradient

    /// Builds the night-sky gradient for a given focus `clarity` (0 = deep
    /// night, 1 = dawn). As clarity rises the horizon warms toward dawn and the
    /// whole sky lifts a touch, so the background visibly responds to the
    /// user's focus state.
    static func livingGradient(clarity: Double) -> LinearGradient {
        let c = max(0, min(1, clarity))
        let horizon = mix(nightHorizon, dawnGlow, c * 0.55)
        let mid = mix(nightMid, dawnViolet, c * 0.30)
        let top = mix(nightTop, nightMid, c * 0.25)
        return LinearGradient(
            colors: [top, mid, horizon],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Linear blend between two colors in sRGB. `t` is clamped 0...1.
    static func mix(_ a: Color, _ b: Color, _ t: Double) -> Color {
        let t = max(0, min(1, t))
        let ca = UIColor(a)
        let cb = UIColor(b)
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        ca.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        cb.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return Color(
            red: Double(r1 + (r2 - r1) * t),
            green: Double(g1 + (g2 - g1) * t),
            blue: Double(b1 + (b2 - b1) * t)
        )
    }

    // MARK: - Signal palette (attention control panel)
    //
    // The newer "Signal" identity used by onboarding and the redesigned tabs: a
    // near-black control-panel surface with a blue→violet signal glow. Distinct
    // from Opal's gem/orb gradients on purpose. The Living Sky tokens above stay
    // for the existing focus-session screens.

    // "Stark minimal" palette — matches the marketing site (lib/signal.ts):
    // true-black canvas, off-white text, hairline rules, one accent used rarely.
    // No gradient glows or gradient buttons (those read as generic/slop).
    static let signalBackground = hex(0x08080A)   // near true black
    static let signalCard = hex(0x0D0D0F)
    static let signalCardRaised = hex(0x141416)
    static let signalBorder = Color.white.opacity(0.08)        // hairline
    static let signalBorderStrong = Color.white.opacity(0.16)
    static let signalText = hex(0xECECEE)         // off-white, not pure
    static let signalTextDim = hex(0x8A8A90)
    static let signalTextFaint = hex(0x56565C)
    static let signalBlue = hex(0x6E8BFF)         // accent — used sparingly
    static let signalViolet = hex(0x8B5CF6)
    static let signalSuccess = hex(0x5FB98E)
    static let signalWarning = hex(0xD8A24A)

    /// Legacy gradient — kept so older references compile, but the stark UI uses
    /// solid white/black buttons and a flat accent, not this.
    static let signalGlow = LinearGradient(
        colors: [signalBlue, signalViolet],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Builds a Color from a 0xRRGGBB literal.
    static func hex(_ value: UInt32) -> Color {
        Color(
            red: Double((value >> 16) & 0xFF) / 255.0,
            green: Double((value >> 8) & 0xFF) / 255.0,
            blue: Double(value & 0xFF) / 255.0
        )
    }
}
