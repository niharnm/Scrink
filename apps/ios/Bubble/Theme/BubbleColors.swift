import SwiftUI

enum BubbleColors {
    // Vibrant sky blue matching the design
    static let skyBlue = Color(red: 0.227, green: 0.553, blue: 0.871)       // #3A8DDE
    static let navyBlue = Color(red: 0.227, green: 0.553, blue: 0.871)      // Same as skyBlue for buttons
    static let white = Color.white
    static let white30 = Color.white.opacity(0.3)
    static let white60 = Color.white.opacity(0.6)

    // Vibrant blue sky gradient - brighter at top, transitioning to clouds
    static let skyGradient = LinearGradient(
        colors: [
            Color(red: 0.4, green: 0.7, blue: 1.0),      // Bright sky blue at top
            Color(red: 0.35, green: 0.65, blue: 0.95),   // Mid blue
            Color(red: 0.3, green: 0.6, blue: 0.9),      // Deeper blue
            Color(red: 0.25, green: 0.55, blue: 0.85)    // Transition to clouds
        ],
        startPoint: .top,
        endPoint: .bottom
    )
}
