import CryptoKit
import Foundation
import os

private let syncLog = Logger(
    subsystem: RinklerConstants.logSubsystem,
    category: "traffic-sync"
)

enum TrafficSyncStatus: Equatable {
    case waitingForTraffic
    case notAuthenticated
    case syncing
    case synced(Date, uploadedCount: Int)
    case failed(String)
}

actor TrafficSyncService {
    private let authClient: SupabaseAuthClient
    private let defaults: UserDefaults?
    private let urlSession: URLSession
    private var isUploading = false

    private let uploadedEventIDsKey = "uploadedTrafficEventClientIDs"
    private let maxStoredEventIDs = 2_000
    private let maxUploadBatchSize = 100

    init(
        authClient: SupabaseAuthClient = .shared,
        defaults: UserDefaults? = UserDefaults(suiteName: RinklerConstants.appGroupID),
        urlSession: URLSession = .shared
    ) {
        self.authClient = authClient
        self.defaults = defaults
        self.urlSession = urlSession
    }

    func uploadNewEvents(_ events: [TrafficEvent]) async -> TrafficSyncStatus {
        if isUploading {
            return .syncing
        }

        let terminalEvents = events
            .filter(Self.shouldUpload)
            .sorted { $0.timestamp < $1.timestamp }

        guard !terminalEvents.isEmpty else {
            return .waitingForTraffic
        }

        let alreadyUploaded = loadUploadedEventIDs()
        var rows: [TrafficEventInsert] = []
        var uploadedIDs: [String] = []

        for event in terminalEvents {
            let clientEventID = Self.clientEventID(for: event)
            guard !alreadyUploaded.contains(clientEventID),
                  let row = TrafficEventInsert(event: event, clientEventID: clientEventID) else {
                continue
            }

            rows.append(row)
            uploadedIDs.append(clientEventID)

            if rows.count == maxUploadBatchSize {
                break
            }
        }

        guard !rows.isEmpty else {
            return .synced(Date(), uploadedCount: 0)
        }

        isUploading = true
        defer { isUploading = false }

        do {
            var authenticated = try await authClient.authenticatedRESTRequest(
                path: "traffic_events",
                method: "POST",
                queryItems: [URLQueryItem(name: "on_conflict", value: "user_id,client_event_id")]
            )

            let payload = rows.map { $0.withUserID(authenticated.session.userID) }
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601

            authenticated.request.httpBody = try encoder.encode(payload)
            authenticated.request.setValue(
                "resolution=ignore-duplicates,return=minimal",
                forHTTPHeaderField: "Prefer"
            )

            let (_, response) = try await urlSession.data(for: authenticated.request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200..<300).contains(httpResponse.statusCode) else {
                let status = (response as? HTTPURLResponse)?.statusCode ?? -1
                // Status code is not user content; log it for diagnosability.
                syncLog.error("Traffic sync rejected by server (HTTP \(status, privacy: .public))")
                return .failed("Traffic sync failed. Check your connection and try again.")
            }

            saveUploadedEventIDs(alreadyUploaded.union(uploadedIDs))
            return .synced(Date(), uploadedCount: rows.count)
        } catch SupabaseAuthError.notAuthenticated {
            return .notAuthenticated
        } catch SupabaseAuthError.missingConfiguration {
            return .failed("Cloud sync is not configured for this build.")
        } catch {
            // Underlying error is redacted by default in release builds; this
            // makes transient network/decode failures diagnosable in Console.
            syncLog.error("Traffic sync failed: \(error.localizedDescription, privacy: .private)")
            return .failed("Traffic sync failed. Check your connection and try again.")
        }
    }

    private static func shouldUpload(_ event: TrafficEvent) -> Bool {
        switch event.type {
        case .completed, .blocked, .streamBlocked, .error:
            return true
        case .allowed:
            return false
        }
    }

    private func loadUploadedEventIDs() -> Set<String> {
        Set(defaults?.stringArray(forKey: uploadedEventIDsKey) ?? [])
    }

    private func saveUploadedEventIDs(_ ids: Set<String>) {
        let trimmed = Array(ids).suffix(maxStoredEventIDs)
        defaults?.set(Array(trimmed), forKey: uploadedEventIDsKey)
    }

    private static func clientEventID(for event: TrafficEvent) -> String {
        let host = normalizedHost(event.sni ?? event.host) ?? "unknown"
        let millis = Int64(event.timestamp.timeIntervalSince1970 * 1_000)
        let raw = "\(millis)|\(event.id)|\(host)|\(event.port)|\(event.type.rawValue)|\(event.bytesDown ?? 0)"
        let digest = SHA256.hash(data: Data(raw.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    static func normalizedHost(_ host: String?) -> String? {
        guard let host else { return nil }
        let cleaned = host
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "www.", with: "", options: [.anchored])
        guard !cleaned.isEmpty, cleaned != "?" else { return nil }
        return cleaned
    }
}

private struct TrafficEventInsert: Encodable {
    let userID: String
    let clientEventID: String
    let timestamp: Date
    let host: String
    let appCategory: String
    let method: String?
    let contentType: String?
    let bytesIn: Int
    let bytesOut: Int
    let wasBlocked: Bool
    let blockReason: String?
    let metadata: TrafficEventMetadata

    init?(event: TrafficEvent, clientEventID: String, userID: String = "") {
        guard let host = TrafficSyncService.normalizedHost(event.sni ?? event.host) else {
            return nil
        }

        self.userID = userID
        self.clientEventID = clientEventID
        self.timestamp = event.timestamp
        self.host = host
        self.appCategory = Self.classifyHost(host)
        self.method = event.port == 443 ? "CONNECT" : nil
        self.contentType = nil
        self.bytesIn = 0
        self.bytesOut = max(event.bytesDown ?? 0, 0)
        self.wasBlocked = event.type == .blocked || event.type == .streamBlocked
        self.blockReason = Self.blockReason(for: event.type)
        self.metadata = TrafficEventMetadata(
            eventType: event.type.rawValue,
            localEventID: event.id,
            port: Int(event.port)
        )
    }

    func withUserID(_ userID: String) -> TrafficEventInsert {
        TrafficEventInsert(
            userID: userID,
            clientEventID: clientEventID,
            timestamp: timestamp,
            host: host,
            appCategory: appCategory,
            method: method,
            contentType: contentType,
            bytesIn: bytesIn,
            bytesOut: bytesOut,
            wasBlocked: wasBlocked,
            blockReason: blockReason,
            metadata: metadata
        )
    }

    private init(
        userID: String,
        clientEventID: String,
        timestamp: Date,
        host: String,
        appCategory: String,
        method: String?,
        contentType: String?,
        bytesIn: Int,
        bytesOut: Int,
        wasBlocked: Bool,
        blockReason: String?,
        metadata: TrafficEventMetadata
    ) {
        self.userID = userID
        self.clientEventID = clientEventID
        self.timestamp = timestamp
        self.host = host
        self.appCategory = appCategory
        self.method = method
        self.contentType = contentType
        self.bytesIn = bytesIn
        self.bytesOut = bytesOut
        self.wasBlocked = wasBlocked
        self.blockReason = blockReason
        self.metadata = metadata
    }

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case clientEventID = "client_event_id"
        case timestamp = "ts"
        case host
        case appCategory = "app_category"
        case method
        case contentType = "content_type"
        case bytesIn = "bytes_in"
        case bytesOut = "bytes_out"
        case wasBlocked = "was_blocked"
        case blockReason = "block_reason"
        case metadata
    }

    private static func blockReason(for type: EventType) -> String? {
        switch type {
        case .blocked:
            return "Blocked by Rinkler filter"
        case .streamBlocked:
            return "Stream limit reached"
        default:
            return nil
        }
    }

    private static func classifyHost(_ host: String) -> String {
        if matches(host, [
            "instagram.com",
            "cdninstagram.com",
            "instagram.net",
            "fbcdn.net",
            "facebook.com",
            "edge-mqtt.facebook.com",
        ]) {
            return "instagram"
        }
        if matches(host, [
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
        ]) {
            return "tiktok"
        }
        if matches(host, [
            "youtube.com",
            "youtube-nocookie.com",
            "youtubei.googleapis.com",
            "googlevideo.com",
            "ytimg.com",
            "yt3.ggpht.com",
            "youtu.be",
        ]) {
            return "youtube"
        }
        if matches(host, ["twitter.com", "x.com", "twimg.com", "t.co"]) {
            return "twitter"
        }
        if matches(host, ["reddit.com", "redd.it", "redditmedia.com", "redditstatic.com"]) {
            return "reddit"
        }
        if matches(host, ["snapchat.com", "sc-cdn.net"]) { return "snapchat" }
        if matches(host, ["openai.com", "anthropic.com", "claude.ai", "perplexity.ai"]) {
            return "ai"
        }
        if matches(host, ["google.com", "googleapis.com", "gstatic.com", "googleusercontent.com"]) {
            return "google"
        }
        if host.hasSuffix(".edu") || matches(host, ["canvaslms.com", "instructure.com", "khanacademy.org"]) {
            return "education"
        }
        if matches(host, ["apple.com", "icloud.com", "cloudflare.com", "akamai", "fastly", "amazonaws.com", "firebaseio.com"]) {
            return "infrastructure"
        }
        return "other"
    }

    private static func matches(_ host: String, _ needles: [String]) -> Bool {
        needles.contains { needle in
            host == needle || host.hasSuffix(".\(needle)") || host.contains(needle)
        }
    }
}

private struct TrafficEventMetadata: Encodable {
    let eventType: String
    let localEventID: Int
    let port: Int

    enum CodingKeys: String, CodingKey {
        case eventType = "event_type"
        case localEventID = "local_event_id"
        case port
    }
}
