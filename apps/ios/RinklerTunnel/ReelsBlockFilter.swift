import Foundation

final class ReelsBlockFilter: ConnectionFilter {

    private let sharedDefaults: UserDefaults?

    init(sharedDefaults: UserDefaults? = UserDefaults(suiteName: RinklerConstants.appGroupID)) {
        self.sharedDefaults = sharedDefaults
    }

    var isEnabled: Bool {
        isFilterEnabled(forKey: RinklerConstants.blockInstagramShortVideoEnabledKey)
            || isFilterEnabled(forKey: RinklerConstants.blockTikTokShortVideoEnabledKey)
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

        // Match exact domains and subdomains only.
        for (domain, threshold) in thresholds {
            if matches(sni: lower, trackedDomain: domain) {
                guard let enabledKey = RinklerConstants.filterEnabledKey(forTrackedDomain: domain),
                      isFilterEnabled(forKey: enabledKey) else {
                    continue
                }
                if threshold == RinklerConstants.noLimitThreshold {
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
        var thresholds = RinklerConstants.defaultDomainThresholds
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: RinklerConstants.domainThresholdsKey),
              let dict = try? JSONDecoder().decode([String: Int].self, from: data) else {
            return thresholds
        }
        for (domain, threshold) in dict {
            thresholds[domain] = threshold
        }
        return thresholds
    }

    private func isFilterEnabled(forKey key: String) -> Bool {
        guard let defaults = sharedDefaults else { return true }
        guard defaults.object(forKey: key) != nil else {
            return true
        }
        return defaults.bool(forKey: key)
    }

    private func matches(sni: String, trackedDomain: String) -> Bool {
        let domain = trackedDomain.lowercased()
        return sni == domain || sni.hasSuffix(".\(domain)")
    }
}
