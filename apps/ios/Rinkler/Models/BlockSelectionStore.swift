import Foundation
import Combine

/// Persists which app feeds the user wants killed and resolves them into the flat
/// host set the tunnel reads (`blockedHostsKey`). Keys are "appId/featureId".
@MainActor
final class BlockSelectionStore: ObservableObject {
    @Published private(set) var enabled: Set<String> = []

    private let defaults = UserDefaults(suiteName: RinklerConstants.appGroupID)
    private let selectionKey = RinklerConstants.blockSelectionFeaturesKey

    init() { load() }

    func isOn(_ appId: String, _ featureId: String) -> Bool {
        enabled.contains(key(appId, featureId))
    }

    func toggle(_ appId: String, _ featureId: String) {
        let k = key(appId, featureId)
        if enabled.contains(k) { enabled.remove(k) } else { enabled.insert(k) }
        persist()
        resolveHosts()
    }

    func anyOn(forApp appId: String) -> Bool {
        enabled.contains { $0.hasPrefix(appId + "/") }
    }

    private func key(_ a: String, _ f: String) -> String { "\(a)/\(f)" }

    private func load() {
        if let arr = defaults?.stringArray(forKey: selectionKey) { enabled = Set(arr) }
        resolveHosts()
    }

    private func persist() {
        defaults?.set(Array(enabled), forKey: selectionKey)
    }

    /// Flattens enabled features → the host set the tunnel blocks at CONNECT.
    private func resolveHosts() {
        defaults?.set(BlockCatalog.hosts(forEnabled: enabled), forKey: RinklerConstants.blockedHostsKey)
    }
}
