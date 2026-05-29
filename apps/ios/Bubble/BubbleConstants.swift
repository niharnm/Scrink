import Foundation

enum BubbleConstants {
    // MARK: - Identifiers
    static let appGroupID = "group.com.rinkler.app"
    static let tunnelBundleID = "com.rinkler.app.tunnel"

    // MARK: - Network Settings
    static let tunnelRemoteAddress = "198.18.0.1"
    static let tunnelLocalAddress = "198.18.0.2"
    static let tunnelSubnetMask = "255.255.255.0"
    static let dnsServers = ["8.8.8.8", "1.1.1.1"]
    // Standard packet-tunnel MTU. A jumbo MTU (e.g. 9000) is not a valid path
    // MTU to real servers and can stall or tear down the tunnel.
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

    // MARK: - Logging
    static let logFileName = "tunnel_log.txt"
    static let maxLogSizeBytes = 512 * 1024
    static let maxStatusLogEntries = 200
    static let logSubsystem = "com.rinkler.app.tunnel"
    static let statsFileName = "traffic_stats.json"

    // MARK: - QUIC / UDP Blocking
    // Short-video video is mostly served over QUIC (HTTP/3) on UDP 443. We block
    // UDP 443 only to IPs known to belong to tracked CDNs, forcing the apps to
    // fall back to TCP/TLS where the byte-threshold stream blocker can act.
    static let quicPort: UInt16 = 443
    static let trackedIPTTL: TimeInterval = 600   // 10 min — covers DNS TTL + reuse
    static let maxTrackedIPs = 4000

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

    static let trackedDomains = instagramTrackedDomains + tiktokTrackedDomains + youtubeTrackedDomains

    static let domainThresholdGroups: [(title: String, domains: [String])] = [
        ("Instagram", instagramTrackedDomains),
        ("TikTok", tiktokTrackedDomains),
        ("YouTube", youtubeTrackedDomains),
    ]

    static var defaultDomainThresholds: [String: Int] {
        Dictionary(uniqueKeysWithValues: trackedDomains.map { ($0, streamBlockDefaultThreshold) })
    }

    // MARK: - UserDefaults Keys
    static let blockInstagramShortVideoEnabledKey = "blockReelsEnabled"
    static let blockTikTokShortVideoEnabledKey = "blockTikTokScrollEnabled"
    static let blockYouTubeShortVideoEnabledKey = "blockYouTubeVideoEnabled"
    static let blockReelsEnabledKey = blockInstagramShortVideoEnabledKey
    static let domainThresholdsKey = "domainThresholds"
    static let optionStatesKey = "optionStates"

    static func filterEnabledKey(forTrackedDomain domain: String) -> String? {
        if instagramTrackedDomains.contains(domain) {
            return blockInstagramShortVideoEnabledKey
        }
        if tiktokTrackedDomains.contains(domain) {
            return blockTikTokShortVideoEnabledKey
        }
        if youtubeTrackedDomains.contains(domain) {
            return blockYouTubeShortVideoEnabledKey
        }
        return nil
    }

    // MARK: - VPN
    static let vpnDescription = "Rinkler Protection"
    static let vpnServerAddress = "rinkler"
}
