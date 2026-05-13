import Foundation

enum Route: Hashable {
    case home
    case blockingOptions(appId: String)
    case magicSignIn
    case codeVerification(email: String)
    // Chungus VPN routes
    case settings
    case trafficDashboard
    case extensionLog
}
