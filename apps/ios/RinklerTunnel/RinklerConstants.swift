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
    // Standard packet-tunnel MTU. A jumbo MTU (e.g. 9000) is not a valid path
    // MTU to real servers: large frames get black-holed or fragmented, which
    // stalls TCP and can tear the tunnel down shortly after it connects. This
    // was the root cause of the tunnel "connecting but no traffic" failure.
    static let mtu: NSNumber = 1500

    // MARK: - tun2socks Configuration
    // HevSocks5Tunnel runs each session on a fixed-size coroutine stack. 24 KB
    // was too small for the UDP forwarding path (hev_socks5_session_udp_fwd_b):
    // the stack overflowed and the process jumped to an unmapped page, crashing
    // the tunnel with EXC_BAD_ACCESS / "Failed to fault in a page with execute
    // permissions". 86016 is the library's own default and the proven-safe value.
    static let tun2socksTaskStackSize = 86016
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
    // Short-video media is largely served over QUIC (HTTP/3) on UDP 443. Because
    // the QUIC handshake is encrypted there is no plaintext SNI to read, so we
    // match QUIC datagrams by destination IP using the set of IPs we learn belong
    // to tracked CDNs (from DNS answers + TLS SNI on parallel TCP/443 sockets).
    // Dropping UDP 443 to those IPs forces the apps to fall back to TCP/TLS, where
    // the byte-threshold stream blocker can actually act. Without this, reels play
    // over QUIC and bypass the filter entirely.
    static let quicPort: UInt16 = 443
    static let trackedIPTTL: TimeInterval = 600   // 10 min — covers DNS TTL + reuse
    static let maxTrackedIPs = 4000

    // MARK: - Ads & Trackers
    // While protection is on, Rinkler also blocks well-known ad/tracker hosts at
    // CONNECT (on by default). Curated to avoid hosts that double as core app
    // APIs (e.g. graph.facebook.com, *.googleapis.com are intentionally absent).
    static let blockAdsTrackersEnabledKey = "blockAdsTrackersEnabled"
    static let adTrackerDomains: Set<String> = [
        // Google ads / analytics
        "doubleclick.net", "googlesyndication.com", "googleadservices.com",
        "google-analytics.com", "googletagmanager.com", "googletagservices.com",
        "adservice.google.com", "2mdn.net", "app-measurement.com",
        // Ad exchanges / SSPs
        "adnxs.com", "rubiconproject.com", "pubmatic.com", "openx.net",
        "criteo.com", "criteo.net", "casalemedia.com", "rlcdn.com",
        "adsrvr.org", "bidswitch.net", "mathtag.com", "3lift.com",
        "amazon-adsystem.com", "moatads.com", "smartadserver.com",
        // Native / recommendation ads
        "taboola.com", "outbrain.com", "scorecardresearch.com",
        "quantserve.com", "quantcount.com",
        // Mobile ad SDKs
        "applovin.com", "adcolony.com", "chartboost.com", "vungle.com",
        "inmobi.com", "mopub.com", "unityads.unity3d.com", "supersonicads.com",
        // Attribution / product-analytics trackers
        "appsflyer.com", "adjust.com", "branch.io", "kochava.com",
        "singular.net", "mixpanel.com", "amplitude.com", "segment.io",
        "fullstory.com", "hotjar.com",
    ]

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

    // Keep YouTube domains observable in analytics, but do not enable a production
    // stream-block rule here. Shorts and normal YouTube playback share the same
    // SNI/media hosts, and this privacy-preserving tunnel cannot inspect HTTPS
    // paths like /shorts without decrypting traffic.
    static let trackedDomains = instagramTrackedDomains + tiktokTrackedDomains

    static var defaultDomainThresholds: [String: Int] {
        Dictionary(uniqueKeysWithValues: trackedDomains.map { ($0, streamBlockDefaultThreshold) })
    }

    // MARK: - UserDefaults Keys
    static let blockInstagramShortVideoEnabledKey = "blockReelsEnabled"
    static let blockTikTokShortVideoEnabledKey = "blockTikTokScrollEnabled"
    static let blockReelsEnabledKey = blockInstagramShortVideoEnabledKey
    static let domainThresholdsKey = "domainThresholds"
    static let optionStatesKey = "optionStates"
    /// Compact schedule written by the app from the user's Focus System rules.
    static let ruleScheduleKey = "ruleSchedule"

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
