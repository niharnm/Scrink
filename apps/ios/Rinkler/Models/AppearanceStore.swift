import SwiftUI
import Combine

/// Drives the app's Light / Dark / System appearance (Settings → Appearance).
///
/// Dark is the brand default — the marketing site is true-black — but people asked
/// for a real choice, so this persists their pick and the colors in
/// `RinklerColors` adapt automatically via dynamic `UIColor`. The selected scheme
/// is applied once at the `RinklerApp` root with `.preferredColorScheme`.
@MainActor
final class AppearanceStore: ObservableObject {
    enum Mode: String, CaseIterable, Identifiable {
        case system, light, dark

        var id: String { rawValue }

        var title: String {
            switch self {
            case .system: return "System"
            case .light: return "Light"
            case .dark: return "Dark"
            }
        }

        /// SF Symbol shown next to each option.
        var icon: String {
            switch self {
            case .system: return "iphone"
            case .light: return "sun.max.fill"
            case .dark: return "moon.fill"
            }
        }

        /// nil means "follow the system" — exactly what `.preferredColorScheme`
        /// expects to defer to the device setting.
        var colorScheme: ColorScheme? {
            switch self {
            case .system: return nil
            case .light: return .light
            case .dark: return .dark
            }
        }
    }

    @Published var mode: Mode {
        didSet { UserDefaults.standard.set(mode.rawValue, forKey: Self.key) }
    }

    private static let key = "rinkler.appearanceMode"

    init() {
        let stored = UserDefaults.standard.string(forKey: Self.key)
        // Default to Dark — it's the on-brand look and keeps the app consistent
        // with the website for anyone who never opens Settings.
        mode = stored.flatMap(Mode.init(rawValue:)) ?? .dark
    }
}
