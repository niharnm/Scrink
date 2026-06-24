import Foundation
import FamilyControls

/// Screen Time (Family Controls) authorization — the permission Rinkler needs to
/// shield whole apps and render the block screen over them.
///
/// This requires Apple's `com.apple.developer.family-controls` entitlement, which
/// is granted by request (developer.apple.com). The code here is safe to ship
/// before that: `requestAccess()` simply throws and `status` stays
/// `.notDetermined` until the entitlement is on the build — then the Screen Time
/// prompt appears with no further code changes.
@MainActor
final class ScreenTimeManager: ObservableObject {
    @Published private(set) var status: AuthorizationStatus

    init() {
        status = AuthorizationCenter.shared.authorizationStatus
    }

    var isAuthorized: Bool { status == .approved }

    func refresh() {
        status = AuthorizationCenter.shared.authorizationStatus
    }

    /// Triggers the iOS "Rinkler Would Like to Access Screen Time" prompt.
    /// Returns true on approval; returns false (no crash) until the entitlement
    /// is live.
    @discardableResult
    func requestAccess() async -> Bool {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            refresh()
            return isAuthorized
        } catch {
            refresh()
            return false
        }
    }

    var statusLabel: String {
        switch status {
        case .approved: return "Granted"
        case .denied: return "Denied"
        default: return "Not set"
        }
    }
}
