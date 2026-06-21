import Foundation

final class ReelsBlockFilter: ConnectionFilter {

    private let sharedDefaults: UserDefaults?
    private let ipStore = TrackedIPStore()

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

    /// QUIC/UDP blocking. Video on the tracked apps rides QUIC (UDP 443); since
    /// the QUIC handshake is encrypted we match by destination IP using the set
    /// of IPs we learned belong to tracked CDNs (from DNS responses + TLS SNI).
    /// Dropping these forces the apps to fall back to TCP/TLS, where the
    /// byte-threshold stream blocker can act.
    func shouldBlockUDP(host: String, port: UInt16) -> FilterDecision {
        guard isEnabled, port == RinklerConstants.quicPort else { return .allow }
        guard let appKey = ipStore.appKey(forIP: host),
              isFilterEnabled(forKey: appKey) else { return .allow }
        return .block
    }

    /// Records hostname→IP mappings learned from a DNS response so that later
    /// QUIC datagrams (which only carry the destination IP) can be matched.
    func recordDNS(host: String, ips: [String]) {
        guard let match = trackedMatch(forHost: host) else { return }
        for ip in ips {
            ipStore.record(ip: ip, domain: match.domain, appKey: match.appKey)
        }
    }

    /// Records an IP as belonging to a tracked domain, learned from the TLS SNI
    /// on a parallel TCP/443 connection.
    func recordSNI(_ sni: String, ip: String) {
        guard let match = trackedMatch(forHost: sni) else { return }
        ipStore.record(ip: ip, domain: match.domain, appKey: match.appKey)
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

    /// Returns the tracked domain and its per-app enable key if `host` matches a
    /// tracked short-video domain whose app filter is currently enabled.
    private func trackedMatch(forHost host: String) -> (domain: String, appKey: String)? {
        let lower = host.lowercased()
        for domain in RinklerConstants.trackedDomains {
            guard matches(sni: lower, trackedDomain: domain),
                  let appKey = RinklerConstants.filterEnabledKey(forTrackedDomain: domain),
                  isFilterEnabled(forKey: appKey) else { continue }
            return (domain, appKey)
        }
        return nil
    }

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
