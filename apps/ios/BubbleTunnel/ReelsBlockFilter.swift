import Foundation

final class ReelsBlockFilter: ConnectionFilter {

    private let sharedDefaults = UserDefaults(suiteName: BubbleConstants.appGroupID)

    var isEnabled: Bool {
        guard let defaults = sharedDefaults else { return true }
        guard defaults.object(forKey: BubbleConstants.blockReelsEnabledKey) != nil else {
            return true
        }
        return defaults.bool(forKey: BubbleConstants.blockReelsEnabledKey)
    }

    // MARK: - ConnectionFilter

    func shouldAllow(host: String, port: UInt16) -> FilterDecision {
        return .allow
    }

    /// Returns the byte threshold for a given SNI domain.
    /// - Returns `nil` if no blocking rule matches (allow unlimited).
    /// - Returns `0` to block immediately.
    /// - Returns `>0` to block after that many bytes.
    func streamBlockThreshold(for sni: String) -> Int? {
        guard isEnabled else { return nil }

        let thresholds = loadDomainThresholds()
        let lower = sni.lowercased()

        // Check each tracked domain — match if the SNI contains it
        for (domain, threshold) in thresholds {
            if lower.contains(domain.lowercased()) {
                if threshold == BubbleConstants.noLimitThreshold {
                    return nil // no limit for this domain
                }
                return threshold
            }
        }

        return nil // no matching rule → allow
    }

    func isStreamBlockTarget(_ domain: String) -> Bool {
        return streamBlockThreshold(for: domain) != nil
    }

    // MARK: - Private

    private func loadDomainThresholds() -> [String: Int] {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: BubbleConstants.domainThresholdsKey),
              let dict = try? JSONDecoder().decode([String: Int].self, from: data) else {
            return [:]
        }
        return dict
    }
}
