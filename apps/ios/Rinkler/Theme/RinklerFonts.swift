import SwiftUI

/// Rinkler typography.
///
/// Two families, strict split:
/// - **Geist Sans** — the entire UI: body, buttons, titles, labels, copy.
/// - **Geist Mono** — figures only: the hero stat, counters, timers, streaks,
///   threshold values. Used sparingly and always with `.monospacedDigit()` so
///   digits stay aligned as they tick. Keeping mono *just* for numbers is what
///   makes it read as "precise data" rather than a techy gimmick.
///
/// The legacy `coolvetica`/`pupok`/`coolveticaItalic` helpers are kept as thin
/// shims that now resolve to Geist Sans, so every screen that still calls them
/// adopts the new face automatically. Genuine number call sites are migrated to
/// `mono(_:)` explicitly.
enum RinklerFonts {
    // MARK: - Geist families

    /// Geist Sans — the main UI font.
    static func sans(_ size: CGFloat, _ weight: SansWeight = .regular) -> Font {
        .custom(weight.postScriptName, size: size)
    }

    /// Geist Mono — numbers only.
    static func mono(_ size: CGFloat, _ weight: MonoWeight = .regular) -> Font {
        .custom(weight.postScriptName, size: size)
    }

    enum SansWeight {
        case regular, medium, semibold, bold
        var postScriptName: String {
            switch self {
            case .regular: return "Geist-Regular"
            case .medium: return "Geist-Medium"
            case .semibold: return "Geist-SemiBold"
            case .bold: return "Geist-Bold"
            }
        }
    }

    enum MonoWeight {
        case regular, medium
        var postScriptName: String {
            switch self {
            case .regular: return "GeistMono-Regular"
            case .medium: return "GeistMono-Medium"
            }
        }
    }

    // MARK: - Compatibility shims (now Geist Sans)

    /// Was Pupok display; now Geist Sans SemiBold for display/emphasis text.
    /// (Number call sites have been migrated to `mono(_:)`.)
    static func pupok(size: CGFloat) -> Font { sans(size, .semibold) }

    /// Was Coolvetica body; now Geist Sans Regular — the everyday UI face.
    static func coolvetica(size: CGFloat) -> Font { sans(size, .regular) }

    /// Geist ships no italic; resolves to Geist Sans Regular.
    static func coolveticaItalic(size: CGFloat) -> Font { sans(size, .regular) }

    // MARK: - Text presets (Geist Sans)

    static let titleLarge = sans(60, .bold)        // landing wordmark
    static let titleMedium = sans(34, .semibold)
    static let titleSmall = sans(24, .semibold)
    static let subtitle = sans(26, .regular)
    static let subtitleItalic = sans(26, .regular)
    static let buttonText = sans(22, .semibold)
    static let optionLabel = sans(16, .medium)
    static let appLabel = sans(18, .medium)
    static let headerTitle = sans(28, .semibold)   // RINKLER header / screen titles

    /// Quiet caption used under numbers and on chips.
    static let caption = sans(13, .medium)
    /// Section / card titles.
    static let cardTitle = sans(19, .semibold)
    /// Hero subtitle line ("of focus protected today") — a label, so Sans.
    static let heroUnit = sans(22, .regular)

    // MARK: - Number presets (Geist Mono)

    /// The one hero number on the home screen ("2h 14m").
    static let hero = mono(64, .medium)
    /// Secondary numbers on stat chips and recap.
    static let statNumber = mono(26, .medium)
}
