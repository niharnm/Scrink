import Foundation

final class ReelsBlockFilter: ConnectionFilter {

    private let sharedDefaults: UserDefaults?
    private let ipStore = TrackedIPStore()
    private let schedule = ScheduleStore()

    init(sharedDefaults: UserDefaults? = UserDefaults(suiteName: RinklerConstants.appGroupID)) {
        self.sharedDefaults = sharedDefaults
    }

    var isEnabled: Bool {
        schedule.anyActive
            || isAdBlockEnabled
            || isFilterEnabled(forKey: RinklerConstants.blockInstagramShortVideoEnabledKey)
            || isFilterEnabled(forKey: RinklerConstants.blockTikTokShortVideoEnabledKey)
    }

    /// Ads/trackers are on by default (absent key == enabled).
    private var isAdBlockEnabled: Bool {
        isFilterEnabled(forKey: RinklerConstants.blockAdsTrackersEnabledKey)
    }

    private func isAdTracker(_ host: String) -> Bool {
        let lower = host.lowercased()
        return RinklerConstants.adTrackerDomains.contains { matches(sni: lower, trackedDomain: $0) }
    }

    // MARK: - ConnectionFilter

    func shouldAllow(host: String, port: UInt16) -> FilterDecision {
        // Block ad/tracker hosts outright while ad-blocking is on. Counts as
        // "noise blocked" in the scroll report.
        if isAdBlockEnabled, isAdTracker(host) { return .block }
        return .allow
    }

    /// QUIC/UDP blocking. Video on the tracked apps rides QUIC (UDP 443); since
    /// the QUIC handshake is encrypted we match by destination IP using the set
    /// of IPs we learned belong to tracked CDNs (from DNS responses + TLS SNI).
    /// Dropping these forces the apps to fall back to TCP/TLS, where the
    /// byte-threshold stream blocker can act.
    func shouldBlockUDP(host: String, port: UInt16) -> FilterDecision {
        guard port == RinklerConstants.quicPort else { return .allow }
        guard let appKey = ipStore.appKey(forIP: host) else { return .allow }
        let ig = appKey == RinklerConstants.blockInstagramShortVideoEnabledKey
        let tt = appKey == RinklerConstants.blockTikTokShortVideoEnabledKey
        // Block if a schedule window is active for this app, or its manual
        // toggle is on. Schedule takes precedence so rules hold on time.
        let wantBlock = schedule.activeWindow(ig: ig, tt: tt) != nil || isFilterEnabled(forKey: appKey)
        return wantBlock ? .block : .allow
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
        let thresholds = loadDomainThresholds()
        let lower = sni.lowercased()

        // Match exact domains and subdomains only.
        for (domain, manualThreshold) in thresholds {
            guard matches(sni: lower, trackedDomain: domain) else { continue }

            let flags = appFlags(forDomain: domain)
            // Schedule takes precedence: if a window is blocking this app now,
            // apply its threshold (0 = block immediately).
            if let window = schedule.activeWindow(ig: flags.ig, tt: flags.tt) {
                return window.th == RinklerConstants.noLimitThreshold ? nil : window.th
            }

            // Otherwise fall back to the manual toggle + per-domain threshold.
            guard let enabledKey = RinklerConstants.filterEnabledKey(forTrackedDomain: domain),
                  isFilterEnabled(forKey: enabledKey) else { continue }
            return manualThreshold == RinklerConstants.noLimitThreshold ? nil : manualThreshold
        }

        return nil // no matching rule → allow
    }

    /// Whether a tracked domain belongs to Instagram and/or TikTok.
    private func appFlags(forDomain domain: String) -> (ig: Bool, tt: Bool) {
        (RinklerConstants.instagramTrackedDomains.contains(domain),
         RinklerConstants.tiktokTrackedDomains.contains(domain))
    }

    func isStreamBlockTarget(_ domain: String) -> Bool {
        return streamBlockThreshold(for: domain) != nil
    }

    // MARK: - Private

    /// Returns the tracked domain and its per-app enable key if `host` matches a
    /// tracked short-video domain.
    private func trackedMatch(forHost host: String) -> (domain: String, appKey: String)? {
        let lower = host.lowercased()
        // Learn IPs for any tracked domain regardless of current enable state,
        // so QUIC blocking is ready the moment a schedule window opens.
        for domain in RinklerConstants.trackedDomains {
            guard matches(sni: lower, trackedDomain: domain),
                  let appKey = RinklerConstants.filterEnabledKey(forTrackedDomain: domain) else { continue }
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
