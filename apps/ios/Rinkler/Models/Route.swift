import Foundation

enum Route: Hashable {
    case home
    case today
    case magicSignIn
    case codeVerification(email: String)
    case settings
    case trafficDashboard
    case extensionLog
    case focusSetup
    case activeSession
    case sessionRecap
    case strictModeSetup
    case friendControl
}
