// RinklerURLFilter — iOS 26 NetworkExtension URL Filter provider (SCAFFOLD).
//
// ⚠️ NOT in the build yet. Activating requires the
//    `com.apple.developer.networking.networkextension.url-filter-provider`
//    entitlement (Apple-approval-gated) + a PIR/Bloom-filter server. See
//    docs/URL_FILTER.md. The NE* symbols below are new in iOS 26 (WWDC25) —
//    VERIFY each against the installed iOS 26 SDK before relying on them; do not
//    trust these signatures from memory.
//
// What's real and ours here: the rule source. The provider's job is to consult
// the user's selected feeds (BlockCatalog feature `urlPatterns`) and return a
// block/allow verdict per full URL — the thing the VPN tunnel fundamentally
// can't do on shared hosts.

import Foundation
#if canImport(NetworkExtension)
import NetworkExtension
#endif

// The patterns the filter should block, resolved from the active rule pack +
// the user's per-feature selections. Shared with the app via the App Group.
enum URLFilterRules {
    static let appGroupID = "group.com.rinkler.app"
    static let selectionKey = "blockSelection.features"   // "appId/featureId" set
    static let cacheKey = "blockRules.cachedPack"         // RulePack JSON (RuleRegistry)

    /// URL glob patterns to block right now (e.g. "instagram.com/reels/*").
    /// In the real provider these compile into the Bloom filter; here we expose
    /// the resolution so the server build + the on-device check share one source.
    static func activePatterns() -> [String] {
        let d = UserDefaults(suiteName: appGroupID)
        let enabled = Set(d?.stringArray(forKey: selectionKey) ?? [])
        // Decode the cached rule pack (same shape as the app's RulePack).
        guard let data = d?.data(forKey: cacheKey),
              let pack = try? JSONDecoder().decode(Pack.self, from: data) else { return [] }
        var out: [String] = []
        for app in pack.apps {
            for f in app.features where enabled.contains("\(app.id)/\(f.id)") {
                out.append(contentsOf: f.urlPatterns)
            }
        }
        return out
    }

    // Minimal mirror of the app's Codable rule pack (kept tiny + local so this
    // target has no dependency on the app target).
    struct Pack: Codable { let version: String; let apps: [App] }
    struct App: Codable { let id: String; let features: [Feature] }
    struct Feature: Codable { let id: String; let urlPatterns: [String] }
}

// MARK: - Provider skeleton (verify against iOS 26 SDK before building)
//
// The exact base class / entry points ship with iOS 26. Expected shape:
//   final class URLFilterProvider: NEURLFilterControlProvider { ... }
// driven from the app via `NEURLFilterManager.shared`. Left as a documented
// skeleton until the entitlement is granted and we can compile against the SDK.
//
// #if canImport(NetworkExtension) && compiler(>=...) && os(iOS)
// @available(iOS 26.0, *)
// final class URLFilterProvider: NEURLFilterControlProvider {
//     // Load URLFilterRules.activePatterns() → match incoming full URLs →
//     // .allow / .drop. Privacy handled by the system (PIR/Bloom/OHTTP).
// }
// #endif
