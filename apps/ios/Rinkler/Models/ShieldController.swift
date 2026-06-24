import Foundation
#if canImport(ManagedSettings)
import ManagedSettings
#endif
#if canImport(FamilyControls)
import FamilyControls
#endif

/// Automatic Mode's whole-app shield — the only mechanism that can enforce from a
/// background wake with no user tap. Entitlement-gated (Phase 2): inert until
/// Apple grants `com.apple.developer.family-controls`, the user grants Screen Time
/// access, and they pick apps to shield. Compiles and no-ops today.
final class ShieldController {
    #if canImport(ManagedSettings)
    private let store = ManagedSettingsStore()
    #endif

    func apply() {
        #if canImport(ManagedSettings) && canImport(FamilyControls)
        guard let data = UserDefaults(suiteName: RinklerConstants.appGroupID)?
            .data(forKey: RinklerConstants.autoModeAppSelectionKey),
              let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data),
              !selection.applicationTokens.isEmpty else { return }
        store.shield.applications = selection.applicationTokens
        #endif
    }

    func clear() {
        #if canImport(ManagedSettings)
        store.shield.applications = nil
        #endif
    }
}
