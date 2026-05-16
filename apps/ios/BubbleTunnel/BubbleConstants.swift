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
    static let mtu: NSNumber = 9000

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

    // MARK: - Stream Blocking
    static let streamBlockDefaultThreshold = 512 * 1024  // 0.5 MB
    static let noLimitThreshold = -1
    static let trackedDomains = [
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
    static var defaultDomainThresholds: [String: Int] {
        Dictionary(uniqueKeysWithValues: trackedDomains.map { ($0, streamBlockDefaultThreshold) })
    }

    // MARK: - UserDefaults Keys
    static let blockReelsEnabledKey = "blockReelsEnabled"
    static let domainThresholdsKey = "domainThresholds"
    static let optionStatesKey = "optionStates"

    // MARK: - VPN
    static let vpnDescription = "Rinkler Protection"
    static let vpnServerAddress = "rinkler"
}
