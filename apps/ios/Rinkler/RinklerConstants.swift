import Foundation

enum RinklerConstants {
    // MARK: - Identifiers
    static let appGroupID = "group.com.rinkler.app"
    static let tunnelBundleID = "com.rinkler.app.tunnel"

    // MARK: - Network Settings
    static let tunnelRemoteAddress = "198.18.0.1"
    static let tunnelLocalAddress = "198.18.0.2"
    static let tunnelSubnetMask = "255.255.255.0"
    static let dnsServers = ["8.8.8.8", "1.1.1.1"]
    // Keep this in sync with the packet tunnel target. A jumbo MTU is not a
    // valid path MTU for real device traffic and can stall or tear down the
    // tunnel shortly after it connects.
    static let mtu: NSNumber = 1500

    // MARK: - tun2socks Configuration
    static let tun2socksTaskStackSize = 24576
    static let tun2socksTCPBufferSize = 4096
    static let tun2socksConnectTimeout = 5000
    static let tun2socksReadWriteTimeout = 60000

    // MARK: - SOCKS5 Proxy
    static let socksBindAddress = "127.0.0.1"
    static let maxUDPFrameSize = 9000
    static let relayBufferSize = 65536
    static let udpRelayTimeout: TimeInterval = 5.0
    static let tcpRelayTimeout: TimeInterval = 120.0
    static let maxConnections = 500
    static let statsInterval: TimeInterval = 10.0

    // MARK: - QUIC / UDP Blocking
    static let quicPort: UInt16 = 443
    static let trackedIPTTL: TimeInterval = 600
    static let maxTrackedIPs = 4000

    // MARK: - Logging
    static let logFileName = "tunnel_log.txt"
    static let maxLogSizeBytes = 512 * 1024
    static let maxStatusLogEntries = 200
    static let logSubsystem = "com.rinkler.app.tunnel"
    static let statsFileName = "traffic_stats.json"

    // MARK: - Stream Blocking
    static let streamBlockDefaultThreshold = 512 * 1024  // 0.5 MB
    static let noLimitThreshold = -1
    static let instagramTrackedDomains = [
        "cdninstagram.com",
        "i.instagram.com",
        "graph.instagram.com",
        "gateway.instagram.com",
        "test-gateway.instagram.com",
        "edge-mqtt.facebook.com",
        "fbcdn.net",
        "fbvideo.net",
        "fbsbx.com",
        "instagram.net",
    ]

    static let tiktokTrackedDomains = [
        "tiktok.com",
        "tiktokcdn.com",
        "tiktokcdn-us.com",
        "tiktokcdn-eu.com",
        "tiktokcdn-in.com",
        "tiktokv.com",
        "byteoversea.com",
        "byteoversea.net",
        "byteimg.com",
        "ibyteimg.com",
        "ibytedtos.com",
        "muscdn.com",
        "musical.ly",
        "snssdk.com",
        "ttwstatic.com",
    ]

    static let youtubeTrackedDomains = [
        "youtube.com",
        "youtube-nocookie.com",
        "youtubei.googleapis.com",
        "googlevideo.com",
        "ytimg.com",
        "yt3.ggpht.com",
        "youtu.be",
    ]

    // Keep YouTube domains available for analytics/classification, but do not
    // expose them as stream-block thresholds. Shorts and normal YouTube playback
    // share SNI/media hosts, and this tunnel cannot inspect HTTPS paths.
    static let trackedDomains = instagramTrackedDomains + tiktokTrackedDomains

    static let domainThresholdGroups: [(title: String, domains: [String])] = [
        ("Instagram", instagramTrackedDomains),
        ("TikTok", tiktokTrackedDomains),
    ]

    static var defaultDomainThresholds: [String: Int] {
        Dictionary(uniqueKeysWithValues: trackedDomains.map { ($0, streamBlockDefaultThreshold) })
    }

    // MARK: - UserDefaults Keys
    static let blockInstagramShortVideoEnabledKey = "blockReelsEnabled"
    static let blockTikTokShortVideoEnabledKey = "blockTikTokScrollEnabled"
    static let blockReelsEnabledKey = blockInstagramShortVideoEnabledKey
    /// Ads/trackers blocker (on by default). Mirror of the tunnel constant so the
    /// app target can read/write the same UserDefaults key.
    static let blockAdsTrackersEnabledKey = "blockAdsTrackersEnabled"
    static let domainThresholdsKey = "domainThresholds"
    static let optionStatesKey = "optionStates"
    /// Flat host set (suffix-matched) the tunnel hard-blocks at CONNECT, resolved
    /// from the user's per-app feed selections (BlockCatalog / BlockSelectionStore).
    static let blockedHostsKey = "blockedHosts"

    // MARK: - Strict Mode (total lockdown) keys
    static let strictModeEnabledKey = "strictModeEnabled"
    static let strictModeStartEpochKey = "strictModeStartEpoch"
    static let strictModeEndEpochKey = "strictModeEndEpoch"
    static let strictModeLockAppRemovalKey = "strictModeLockAppRemoval"
    static let strictModeAppSelectionKey = "strictModeAppSelection"
    static let strictModeArmedReceiptsKey = "strictModeArmedReceipts"

    // MARK: - Automatic (health-aware) Mode keys
    static let autoModeEnabledKey = "autoMode.enabled"
    static let autoModeSensitivityKey = "autoMode.sensitivity"        // soft/normal/strict
    static let autoModeBaselineKey = "autoMode.baseline"             // JSON HealthBaseline
    static let autoModeStateKey = "autoMode.lastState"               // JSON DerivedState
    static let autoModeActiveSnapshotKey = "autoMode.activeSnapshot" // prior knobs while tightened
    static let autoModeLogKey = "autoMode.transparencyLog"           // JSON [AutoModeLogEntry]
    static let autoModeLastEvalKey = "autoMode.lastEvalAt"           // ISO date
    static let autoModeConsecutiveKey = "autoMode.consecutive"       // hysteresis counter
    static let autoModeShieldEnabledKey = "autoMode.shieldEnabled"   // Phase 2 gate
    static let autoModeAppSelectionKey = "autoMode.appSelection"     // encoded FamilyActivitySelection
    static let healthBgRefreshID = "com.rinkler.app.healthcheck"

    static func filterEnabledKey(forTrackedDomain domain: String) -> String? {
        if instagramTrackedDomains.contains(domain) {
            return blockInstagramShortVideoEnabledKey
        }
        if tiktokTrackedDomains.contains(domain) {
            return blockTikTokShortVideoEnabledKey
        }
        return nil
    }

    // MARK: - VPN
    static let vpnDescription = "Rinkler Protection"
    static let vpnServerAddress = "rinkler"
}
