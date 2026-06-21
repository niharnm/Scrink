import Foundation

// MARK: - Top-level wrapper

struct TrafficData: Codable {
    let snapshots: [TrafficSnapshot]
    let events: [TrafficEvent]
}

// MARK: - Snapshots

struct TrafficSnapshot: Codable {
    let timestamp: Date
    let connections: [ConnectionSnapshot]
    let stats: StatsSnapshot
    let topDomains: [DomainSnapshot]
}

struct ConnectionSnapshot: Codable, Identifiable {
    let id: Int
    let host: String
    let port: UInt16
    let sni: String?
    let startTime: Date
    let bytesUp: Int
    let bytesDown: Int
    let isActive: Bool

    var totalBytes: Int { bytesUp + bytesDown }
}

struct StatsSnapshot: Codable {
    let totalConns: Int
    let tcpAllowed: Int
    let tcpBlocked: Int
    let udpRelayed: Int
    let errors: Int
}

struct DomainSnapshot: Codable, Identifiable {
    var id: String { domain }
    let domain: String
    let count: Int
    let totalBytes: Int
}

// MARK: - Events

enum EventType: String, Codable {
    case allowed
    case blocked
    case streamBlocked
    case error
    case completed
}

struct TrafficEvent: Codable, Identifiable {
    let id: Int
    let timestamp: Date
    let type: EventType
    let host: String
    let port: UInt16
    let sni: String?
    let detail: String
    let bytesDown: Int?
}
