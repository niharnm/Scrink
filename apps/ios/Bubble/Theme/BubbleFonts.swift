import SwiftUI

enum BubbleFonts {
    // MARK: - Font Families

    static func pupok(size: CGFloat) -> Font {
        .custom("SKPupok-Solid", size: size)
    }

    static func coolvetica(size: CGFloat) -> Font {
        .custom("Coolvetica-Regular", size: size)
    }

    static func coolveticaItalic(size: CGFloat) -> Font {
        .custom("Coolvetica-Italic", size: size)
    }

    // MARK: - Presets

    static let titleLarge = pupok(size: 64)
    static let titleMedium = pupok(size: 36)
    static let titleSmall = pupok(size: 24)
    static let subtitle = coolvetica(size: 28)
    static let subtitleItalic = coolveticaItalic(size: 28)
    static let buttonText = pupok(size: 36)
    static let optionLabel = coolvetica(size: 16)
    static let appLabel = pupok(size: 18)
    static let headerTitle = pupok(size: 32)
}
