import Foundation
import Combine
#if canImport(FamilyControls)
import FamilyControls
#endif
#if canImport(ManagedSettings)
import ManagedSettings
#endif

/// Opal-style whole-app blocking via the Family Controls Shield. The user picks
/// apps with the system picker; when "block now" is on (and Screen Time is
/// authorized) those apps are shielded — the reliable hard block, on top of
/// Rinkler's per-feed filtering. Uses its own named ManagedSettings store so it
/// never clobbers Strict / Auto mode shields.
@MainActor
final class BlockedAppsStore: ObservableObject {
    @Published var enabled: Bool
    #if canImport(FamilyControls)
    @Published var selection = FamilyActivitySelection()
    #endif

    private let defaults = UserDefaults(suiteName: RinklerConstants.appGroupID)
    private weak var screenTime: ScreenTimeManager?
    #if canImport(ManagedSettings)
    private let store = ManagedSettingsStore()
    #endif

    init() {
        enabled = defaults?.bool(forKey: "blockedApps.enabled") ?? false
        #if canImport(FamilyControls)
        if let data = defaults?.data(forKey: "blockedApps.selection"),
           let sel = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            selection = sel
        }
        #endif
    }

    func configure(screenTime: ScreenTimeManager) {
        self.screenTime = screenTime
        apply()
    }

    var appCount: Int {
        #if canImport(FamilyControls)
        return selection.applicationTokens.count + selection.categoryTokens.count
        #else
        return 0
        #endif
    }

    func setEnabled(_ on: Bool) {
        enabled = on
        defaults?.set(on, forKey: "blockedApps.enabled")
        apply()
    }

    #if canImport(FamilyControls)
    func setSelection(_ sel: FamilyActivitySelection) {
        selection = sel
        if let data = try? JSONEncoder().encode(sel) {
            defaults?.set(data, forKey: "blockedApps.selection")
        }
        apply()
    }
    #endif

    func apply() {
        #if canImport(ManagedSettings) && canImport(FamilyControls)
        guard screenTime?.isAuthorized == true, enabled, !selection.applicationTokens.isEmpty else {
            store.shield.applications = nil
            return
        }
        store.shield.applications = selection.applicationTokens
        #endif
    }
}
