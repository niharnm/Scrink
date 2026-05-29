import Foundation
import os

/// Maps resolved IP addresses back to the tracked short-video domain (and the
/// per-app enable key) they belong to.
///
/// Short-video apps serve their feed video over QUIC (HTTP/3, UDP port 443).
/// QUIC's handshake is encrypted, so — unlike TLS-over-TCP — we cannot read the
/// SNI to know which domain a UDP datagram is headed to. Instead we learn the
/// IP→domain mapping from two plaintext sources that always precede the video
/// traffic:
///   1. DNS responses (UDP port 53) — the answer records give us hostname→IPs.
///   2. TLS ClientHello SNI on the parallel TCP/443 connections the apps open.
///
/// Once an IP is known to belong to a tracked CDN, the proxy blocks UDP/443 to
/// it, forcing the app to fall back to TCP/TLS where the byte-threshold stream
/// blocker can actually act.
final class TrackedIPStore {

    private struct Entry {
        let appKey: String      // the per-app UserDefaults enable key
        let domain: String      // the tracked domain it matched
        let expiry: Date
    }

    private let lock = OSAllocatedUnfairLock(initialState: [String: Entry]())
    private let ttl: TimeInterval

    init(ttl: TimeInterval = BubbleConstants.trackedIPTTL) {
        self.ttl = ttl
    }

    // MARK: - Recording

    /// Records that `ip` belongs to `domain` (which mapped to `appKey`).
    func record(ip: String, domain: String, appKey: String) {
        let entry = Entry(appKey: appKey, domain: domain, expiry: Date().addingTimeInterval(ttl))
        lock.withLock { table in
            table[ip] = entry
            // Opportunistic prune so the table cannot grow unbounded.
            if table.count > BubbleConstants.maxTrackedIPs {
                let now = Date()
                table = table.filter { $0.value.expiry > now }
            }
        }
    }

    // MARK: - Lookup

    /// Returns the tracked domain for an IP if it is currently known and not
    /// expired, else nil.
    func trackedDomain(forIP ip: String) -> String? {
        lock.withLock { table in
            guard let entry = table[ip] else { return nil }
            guard entry.expiry > Date() else {
                table.removeValue(forKey: ip)
                return nil
            }
            return entry.domain
        }
    }

    /// Returns the per-app enable key for an IP if known, else nil.
    func appKey(forIP ip: String) -> String? {
        lock.withLock { table in
            guard let entry = table[ip] else { return nil }
            guard entry.expiry > Date() else {
                table.removeValue(forKey: ip)
                return nil
            }
            return entry.appKey
        }
    }

    // MARK: - DNS Response Parsing

    /// Parses a DNS response payload and returns (queriedName, [IP strings]).
    /// Returns nil if the payload is not a parseable DNS answer with addresses.
    static func parseDNSResponse(_ data: Data) -> (host: String, ips: [String])? {
        let bytes = [UInt8](data)
        // Header is 12 bytes: ID(2) FLAGS(2) QD(2) AN(2) NS(2) AR(2)
        guard bytes.count >= 12 else { return nil }

        let flags = (Int(bytes[2]) << 8) | Int(bytes[3])
        let isResponse = (flags & 0x8000) != 0
        guard isResponse else { return nil }

        let qdCount = (Int(bytes[4]) << 8) | Int(bytes[5])
        let anCount = (Int(bytes[6]) << 8) | Int(bytes[7])
        guard qdCount >= 1, anCount >= 1 else { return nil }

        var offset = 12

        // --- Question section: read the first QNAME, then skip QTYPE+QCLASS.
        guard let (qname, afterName) = readName(bytes, at: offset) else { return nil }
        offset = afterName + 4 // QTYPE(2) + QCLASS(2)
        // Skip any additional questions.
        for _ in 1..<max(qdCount, 1) {
            guard let next = skipName(bytes, at: offset) else { return nil }
            offset = next + 4
        }

        // --- Answer section: collect A / AAAA addresses.
        var ips: [String] = []
        for _ in 0..<anCount {
            guard let afterAnswerName = skipName(bytes, at: offset) else { break }
            offset = afterAnswerName
            guard offset + 10 <= bytes.count else { break }
            let type = (Int(bytes[offset]) << 8) | Int(bytes[offset + 1])
            let rdLength = (Int(bytes[offset + 8]) << 8) | Int(bytes[offset + 9])
            let rdStart = offset + 10
            guard rdStart + rdLength <= bytes.count else { break }

            if type == 1, rdLength == 4 { // A record
                ips.append("\(bytes[rdStart]).\(bytes[rdStart + 1]).\(bytes[rdStart + 2]).\(bytes[rdStart + 3])")
            } else if type == 28, rdLength == 16 { // AAAA record
                let parts = (0..<8).map { i in
                    String(format: "%x", (Int(bytes[rdStart + i * 2]) << 8) | Int(bytes[rdStart + i * 2 + 1]))
                }
                ips.append(parts.joined(separator: ":"))
            }
            offset = rdStart + rdLength
        }

        guard !ips.isEmpty else { return nil }
        return (qname, ips)
    }

    /// Reads a DNS name starting at `offset`, following compression pointers.
    /// Returns the decoded name and the offset immediately after the name in
    /// the *original* sequence (not following the pointer).
    private static func readName(_ bytes: [UInt8], at offset: Int) -> (name: String, next: Int)? {
        var labels: [String] = []
        var idx = offset
        var jumped = false
        var afterPointer = offset
        var safety = 0

        while idx < bytes.count {
            safety += 1
            if safety > 128 { return nil } // guard against malformed loops
            let len = Int(bytes[idx])
            if len == 0 {
                if !jumped { afterPointer = idx + 1 }
                break
            }
            if (len & 0xC0) == 0xC0 { // compression pointer
                guard idx + 1 < bytes.count else { return nil }
                if !jumped { afterPointer = idx + 2 }
                let pointer = ((len & 0x3F) << 8) | Int(bytes[idx + 1])
                idx = pointer
                jumped = true
                continue
            }
            let start = idx + 1
            guard start + len <= bytes.count else { return nil }
            if let label = String(bytes: bytes[start..<(start + len)], encoding: .utf8) {
                labels.append(label)
            }
            idx = start + len
        }

        return (labels.joined(separator: "."), afterPointer)
    }

    /// Like readName but only returns the offset after the name.
    private static func skipName(_ bytes: [UInt8], at offset: Int) -> Int? {
        return readName(bytes, at: offset)?.next
    }
}
