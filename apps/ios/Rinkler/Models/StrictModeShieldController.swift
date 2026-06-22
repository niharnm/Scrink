import Foundation
#if canImport(ManagedSettings)
import ManagedSettings
#endif
#if canImport(FamilyControls)
import FamilyControls
#endif

/// Applies the OS-level part of Strict Mode via ManagedSettings: shields the
/// chosen apps (can't be launched) and, for total lockdown, denies app removal
/// device-wide.
///
/// Everything is gated behind `#if canImport(ManagedSettings)` and is only ever
/// *called* when `ScreenTimeManager.isAuthorized` is true, so the pre-entitlement
/// build compiles and these are inert no-ops until Apple grants
/// `com.apple.developer.family-controls` and the user grants Screen Time access.
final class StrictModeShieldController {
    #if canImport(ManagedSettings)
    private let store = ManagedSettingsStore()
    #endif

    /// Shields the persisted app selection and (optionally) blocks app removal.
    func apply(lockAppRemoval: Bool) {
        #if canImport(ManagedSettings) && canImport(FamilyControls)
        if let data = UserDefaults(suiteName: RinklerConstants.appGroupID)?
            .data(forKey: RinklerConstants.strictModeAppSelectionKey),
           let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data),
           !selection.applicationTokens.isEmpty {
            store.shield.applications = selection.applicationTokens
        }
        // "Total lockdown" — blocks deleting ANY app (including Rinkler) until the
        // window ends. The honest escape is iOS Settings → Screen Time.
        store.application.denyAppRemoval = lockAppRemoval ? true : nil
        #endif
    }

    func clear() {
        #if canImport(ManagedSettings)
        store.shield.applications = nil
        store.application.denyAppRemoval = nil
        store.clearAllSettings()
        #endif
    }
}
