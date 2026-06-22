import Foundation
import Network
import os

// MARK: - Connection Filter Protocol

protocol ConnectionFilter {
    func shouldAllow(host: String, port: UInt16) -> FilterDecision
    func shouldBlockUDP(host: String, port: UInt16) -> FilterDecision
    func recordDNS(host: String, ips: [String])
    func recordSNI(_ sni: String, ip: String)
    func isStreamBlockTarget(_ domain: String) -> Bool
    func streamBlockThreshold(for sni: String) -> Int?
}

enum FilterDecision {
    case allow
    case block
}

// MARK: - SOCKS5 Errors

enum SOCKSError: Error, LocalizedError {
    case invalidPort(UInt16)
    case listenerFailed(Error)
    case connectionLimitReached

    var errorDescription: String? {
        switch self {
        case .invalidPort(let p): return "Invalid SOCKS port: \(p)"
        case .listenerFailed(let e): return "Listener failed: \(e.localizedDescription)"
        case .connectionLimitReached: return "Maximum connection limit reached"
        }
    }
}

// MARK: - Parsed Address

private struct ParsedAddress {
    let host: String
    let port: UInt16
    let headerEndOffset: Int
}

// MARK: - SOCKS5 Proxy Server

final class SOCKSProxyServer {

    private var listener: NWListener?
    private let filter: ConnectionFilter
    private let queue = DispatchQueue(label: "com.rinkler.app.socks5", qos: .userInitiated)
    private let log = TunnelLogger.shared
    private var connectionCount = 0      // total connections ever (used as ID)
    private var activeConnectionCount = 0 // currently open connections

    // Thread-safe actual port (written on queue, read from outside)
    private let _actualPort = OSAllocatedUnfairLock(initialState: UInt16(0))
    var actualPort: UInt16 {
        _actualPort.withLock { $0 }
    }

    // Connection stats (queue-confined)
    private var statsAllowed = 0
    private var statsBlocked = 0
    private var statsUDP = 0
    private var statsErrors = 0
    private var statsTimer: DispatchSourceTimer?

    // Active relay tracking for JSON stats
    private var activeRelays: [Int: RelayTracker] = [:]
    private var domainStats: [String: (count: Int, bytes: Int)] = [:]
    private var snapshotTimer: DispatchSourceTimer?
    private var snapshotHistory: [TrafficSnapshot] = []
    private var eventLog: [TrafficEvent] = []
    private var eventCounter = 0
    private let maxSnapshotHistory = 300 // 5 minutes at 1/sec
    private let maxEvents = 500
    private let statsFileURL: URL?

    init(filter: ConnectionFilter) {
        self.filter = filter
        if let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: RinklerConstants.appGroupID
        ) {
            self.statsFileURL = container.appendingPathComponent(RinklerConstants.statsFileName)
        } else {
            self.statsFileURL = nil
        }
    }

    // MARK: - Lifecycle

    func start(ready: @escaping (Error?) -> Void) {
        var didCallReady = false
        let callReady = { (error: Error?) in
            guard !didCallReady else { return }
            didCallReady = true
            ready(error)
        }

        let params = NWParameters.tcp
        guard let anyPort = NWEndpoint.Port(rawValue: 0) else {
            log.log("SOCKS5: Failed to create port 0 endpoint")
            callReady(SOCKSError.invalidPort(0))
            return
        }
        params.requiredLocalEndpoint = NWEndpoint.hostPort(
            host: NWEndpoint.Host(RinklerConstants.socksBindAddress),
            port: anyPort
        )

        let listener: NWListener
        do {
            listener = try NWListener(using: params)
        } catch {
            log.log("SOCKS5: Failed to create listener: \(error)")
            callReady(error)
            return
        }
        self.listener = listener

        listener.stateUpdateHandler = { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .ready:
                let port = listener.port?.rawValue ?? 0
                self._actualPort.withLock { $0 = port }
                self.log.log("SOCKS5: Listening on port \(port)")
                callReady(nil)
            case .waiting(let error):
                let port = listener.port?.rawValue ?? 0
                self._actualPort.withLock { $0 = port }
                self.log.log("SOCKS5: Listener waiting (\(error)), port=\(port)")
                callReady(nil)
            case .failed(let error):
                self.log.log("SOCKS5: Listener failed: \(error)")
                callReady(error)
            case .cancelled:
                self.log.log("SOCKS5: Listener cancelled")
            default:
                break
            }
        }

        listener.newConnectionHandler = { [weak self] connection in
            self?.handleNewConnection(connection)
        }

        listener.start(queue: queue)
        startStatsTimer()
        startSnapshotTimer()
    }

    func stop() {
        queue.sync {
            statsTimer?.cancel()
            statsTimer = nil
            snapshotTimer?.cancel()
            snapshotTimer = nil
        }
        listener?.cancel()
        listener = nil
    }

    private func startStatsTimer() {
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + RinklerConstants.statsInterval, repeating: RinklerConstants.statsInterval)
        timer.setEventHandler { [weak self] in
            guard let self = self else { return }
            let total = self.connectionCount
            guard total > 0 else { return }
            let memMB = Self.memoryUsageMB()
            self.log.log("SOCKS5 STATS: \(total) total, \(self.activeConnectionCount) active, \(self.activeRelays.count) relays, \(self.statsAllowed) allowed, \(self.statsBlocked) blocked, \(self.statsUDP) UDP, \(self.statsErrors) errors, snapshots=\(self.snapshotHistory.count), mem=\(memMB)MB")
        }
        timer.resume()
        statsTimer = timer
    }

    // MARK: - Event Recording

    private func recordEvent(type: EventType, connId: Int, host: String, port: UInt16, sni: String? = nil, detail: String, bytesDown: Int? = nil) {
        eventCounter += 1
        let event = TrafficEvent(
            id: eventCounter,
            timestamp: Date(),
            type: type,
            host: host,
            port: port,
            sni: sni,
            detail: detail,
            bytesDown: bytesDown
        )
        eventLog.append(event)
        if eventLog.count > maxEvents {
            eventLog.removeFirst(eventLog.count - maxEvents)
        }
    }

    // MARK: - JSON Snapshot Writer

    private func startSnapshotTimer() {
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + 1.0, repeating: 1.0)
        timer.setEventHandler { [weak self] in
            self?.writeSnapshot()
        }
        timer.resume()
        snapshotTimer = timer
    }

    private func writeSnapshot() {
        guard let fileURL = statsFileURL else { return }

        let connections = activeRelays.values.map { tracker in
            ConnectionSnapshot(
                id: tracker.id,
                host: tracker.host,
                port: tracker.port,
                sni: tracker.sni,
                startTime: tracker.startTime,
                bytesUp: tracker.bytesUp,
                bytesDown: tracker.bytesDown,
                isActive: !tracker.logged
            )
        }.sorted { $0.id > $1.id }

        let stats = StatsSnapshot(
            totalConns: connectionCount,
            tcpAllowed: statsAllowed,
            tcpBlocked: statsBlocked,
            udpRelayed: statsUDP,
            errors: statsErrors
        )

        let topDomains = domainStats
            .map { DomainSnapshot(domain: $0.key, count: $0.value.count, totalBytes: $0.value.bytes) }
            .sorted { $0.totalBytes > $1.totalBytes }
            .prefix(10)

        let snapshot = TrafficSnapshot(
            timestamp: Date(),
            connections: connections,
            stats: stats,
            topDomains: Array(topDomains)
        )

        // Append to ring buffer
        snapshotHistory.append(snapshot)
        if snapshotHistory.count > maxSnapshotHistory {
            snapshotHistory.removeFirst(snapshotHistory.count - maxSnapshotHistory)
        }

        // Write full history + events so the app gets everything even when backgrounded
        let trafficData = TrafficData(snapshots: snapshotHistory, events: eventLog)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(trafficData) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    // MARK: - Connection Handling

    private func handleNewConnection(_ client: NWConnection) {
        connectionCount += 1
        activeConnectionCount += 1

        if activeConnectionCount > RinklerConstants.maxConnections {
            log.log("SOCKS5: Active connection limit reached (\(activeConnectionCount)/\(RinklerConstants.maxConnections)), rejecting #\(connectionCount)")
            statsErrors += 1
            recordEvent(type: .error, connId: connectionCount, host: "?", port: 0, detail: "Connection limit reached (\(activeConnectionCount)/\(RinklerConstants.maxConnections))")
            activeConnectionCount -= 1
            client.cancel()
            return
        }

        let id = connectionCount
        if id % 50 == 0 {
            log.log("SOCKS5 DIAG: conn #\(id), active=\(activeConnectionCount), relays=\(activeRelays.count), totalAllowed=\(statsAllowed), totalBlocked=\(statsBlocked), errors=\(statsErrors)")
        }
        client.start(queue: queue)
        readMethodNegotiation(client: client, id: id)
    }

    // MARK: - SOCKS5 Method Negotiation

    private func readMethodNegotiation(client: NWConnection, id: Int) {
        client.receive(minimumIncompleteLength: 3, maximumLength: 512) { [weak self] data, _, _, error in
            guard let self = self, let data = data, error == nil else {
                self?.log.log("SOCKS5 #\(id): Method negotiation failed: \(String(describing: error))")
                self?.statsErrors += 1
                self?.recordEvent(type: .error, connId: id, host: "?", port: 0, detail: "Method negotiation failed: \(String(describing: error))")
                self?.activeConnectionCount -= 1
                client.cancel()
                return
            }

            let bytes = [UInt8](data)
            guard bytes.count >= 3, bytes[0] == 0x05 else {
                self.log.log("SOCKS5 #\(id): Invalid SOCKS version or short handshake (\(bytes.count) bytes)")
                self.statsErrors += 1
                self.activeConnectionCount -= 1
                client.cancel()
                return
            }

            let nmethods = Int(bytes[1])
            let handshakeLen = 2 + nmethods
            let excess: Data? = bytes.count > handshakeLen ? Data(bytes[handshakeLen...]) : nil

            let reply = Data([0x05, 0x00])
            client.send(content: reply, completion: .contentProcessed { error in
                if error != nil {
                    self.log.log("SOCKS5 #\(id): Failed to send method reply: \(String(describing: error))")
                    self.statsErrors += 1
                    self.activeConnectionCount -= 1
                    client.cancel()
                    return
                }
                self.readRequest(client: client, id: id, buffered: excess)
            })
        }
    }

    // MARK: - SOCKS5 Request (CONNECT / FWD_UDP)

    private func readRequest(client: NWConnection, id: Int, buffered: Data?) {
        if let buffered = buffered, buffered.count >= 4 {
            self.parseRequest(client: client, id: id, data: buffered)
            return
        }

        let existingBytes = buffered ?? Data()

        client.receive(minimumIncompleteLength: 4 - existingBytes.count, maximumLength: 512) { [weak self] data, _, _, error in
            guard let self = self, let data = data, error == nil else {
                self?.log.log("SOCKS5 #\(id): Request read failed: \(String(describing: error))")
                self?.statsErrors += 1
                self?.recordEvent(type: .error, connId: id, host: "?", port: 0, detail: "Request read failed: \(String(describing: error))")
                self?.activeConnectionCount -= 1
                client.cancel()
                return
            }
            self.parseRequest(client: client, id: id, data: existingBytes + data)
        }
    }

    private func parseRequest(client: NWConnection, id: Int, data: Data) {
        let bytes = [UInt8](data)

        guard bytes.count >= 4, bytes[0] == 0x05 else {
            self.statsErrors += 1
            self.activeConnectionCount -= 1
            log.log("SOCKS5 #\(id): Invalid request (ver=\(bytes.first.map(String.init) ?? "nil"), len=\(bytes.count))")
            client.cancel()
            return
        }

        let cmd = bytes[1]
        let atyp = bytes[3]

        // Parse address using shared helper (ATYP is at byte index 3)
        guard let addr = parseSOCKSAddress(from: bytes, atypOffset: 3) else {
            self.statsErrors += 1
            self.activeConnectionCount -= 1
            log.log("SOCKS5 #\(id): Failed to parse destination address")
            self.sendSocksError(client: client, reply: 0x08)
            return
        }

        // Diagnostic: log ATYP so we know if tun2socks sends domains or IPs
        let atypName: String
        switch atyp {
        case 0x01: atypName = "IPv4"
        case 0x03: atypName = "DOMAIN"
        case 0x04: atypName = "IPv6"
        default: atypName = "UNKNOWN(\(atyp))"
        }

        switch cmd {
        case 0x01: // CONNECT (TCP)
            log.log("TCP #\(id): CONNECT atyp=\(atypName) host=\(addr.host) port=\(addr.port)")
            handleConnect(client: client, id: id, host: addr.host, port: addr.port)

        case 0x05: // FWD_UDP (hev-socks5-tunnel custom extension)
            handleFwdUDP(client: client, id: id)

        default:
            self.statsErrors += 1
            self.activeConnectionCount -= 1
            log.log("SOCKS5 #\(id): unsupported cmd=\(cmd)")
            self.sendSocksError(client: client, reply: 0x07)
        }
    }

    // MARK: - Shared Address Parser

    /// Parses ATYP + address + port from a byte buffer.
    /// `atypOffset` is the index of the ATYP byte in the buffer.
    /// Returns nil if the buffer is too short or address type is unknown.
    private func parseSOCKSAddress(from bytes: [UInt8], atypOffset: Int) -> ParsedAddress? {
        guard bytes.count > atypOffset else { return nil }
        let atyp = bytes[atypOffset]
        let addrStart = atypOffset + 1

        switch atyp {
        case 0x01: // IPv4
            guard bytes.count >= addrStart + 4 + 2 else { return nil }
            let host = "\(bytes[addrStart]).\(bytes[addrStart + 1]).\(bytes[addrStart + 2]).\(bytes[addrStart + 3])"
            let portOffset = addrStart + 4
            let port = (UInt16(bytes[portOffset]) << 8) | UInt16(bytes[portOffset + 1])
            return ParsedAddress(host: host, port: port, headerEndOffset: portOffset + 2)

        case 0x03: // Domain name
            guard bytes.count > addrStart else { return nil }
            let domainLen = Int(bytes[addrStart])
            let domainStart = addrStart + 1
            guard bytes.count >= domainStart + domainLen + 2 else { return nil }
            guard let domain = String(bytes: Array(bytes[domainStart..<(domainStart + domainLen)]), encoding: .utf8) else {
                return nil
            }
            let portOffset = domainStart + domainLen
            let port = (UInt16(bytes[portOffset]) << 8) | UInt16(bytes[portOffset + 1])
            return ParsedAddress(host: domain, port: port, headerEndOffset: portOffset + 2)

        case 0x04: // IPv6
            guard bytes.count >= addrStart + 16 + 2 else { return nil }
            let parts = (0..<8).map { i in
                String(format: "%02x%02x", bytes[addrStart + i * 2], bytes[addrStart + i * 2 + 1])
            }
            let host = parts.joined(separator: ":")
            let portOffset = addrStart + 16
            let port = (UInt16(bytes[portOffset]) << 8) | UInt16(bytes[portOffset + 1])
            return ParsedAddress(host: host, port: port, headerEndOffset: portOffset + 2)

        default:
            return nil
        }
    }

    // MARK: - CONNECT (TCP)

    private func handleConnect(client: NWConnection, id: Int, host: String, port: UInt16) {
        let decision = self.filter.shouldAllow(host: host, port: port)

        switch decision {
        case .block:
            self.statsBlocked += 1
            self.activeConnectionCount -= 1
            self.log.log("SOCKS5 #\(id): BLOCKED \(host):\(port)")
            self.recordEvent(type: .blocked, connId: id, host: host, port: port, detail: "Connection blocked by filter")
            self.sendSocksError(client: client, reply: 0x05)

        case .allow:
            self.statsAllowed += 1
            self.recordEvent(type: .allowed, connId: id, host: host, port: port, detail: "TCP CONNECT")
            self.connectToTarget(client: client, host: host, port: port, id: id)
        }
    }

    // MARK: - FWD_UDP (hev-socks5-tunnel custom command 0x05)
    //
    // Protocol after SOCKS5 handshake + FWD_UDP accept:
    //   Each UDP datagram is framed over TCP as:
    //     [2-byte BE length N][N bytes of SOCKS5 UDP frame]
    //   Where the SOCKS5 UDP frame is:
    //     [RSV 2][FRAG 1][ATYP 1][DST.ADDR var][DST.PORT 2][UDP payload]

    private func handleFwdUDP(client: NWConnection, id: Int) {
        log.log("UDP #\(id): FWD_UDP accepted, starting frame relay")
        let reply = buildSocksReply(reply: 0x00, atyp: 0x01, addr: [0, 0, 0, 0], port: 0)
        client.send(content: reply, completion: .contentProcessed { [weak self] error in
            if error != nil {
                self?.log.log("UDP #\(id): Failed to send FWD_UDP reply: \(String(describing: error))")
                client.cancel()
                return
            }
            self?.readUDPFrameLength(client: client, id: id)
        })
    }

    private func readUDPFrameLength(client: NWConnection, id: Int) {
        client.receive(minimumIncompleteLength: 2, maximumLength: 2) { [weak self] data, _, isComplete, error in
            guard let self = self else { return }
            guard let data = data, data.count >= 2, error == nil else {
                self.log.log("UDP #\(id): frame length read failed, isComplete=\(isComplete), error=\(String(describing: error))")
                client.cancel()
                return
            }

            let bytes = [UInt8](data)
            let frameLen = (Int(bytes[0]) << 8) | Int(bytes[1])

            guard frameLen > 0, frameLen <= RinklerConstants.maxUDPFrameSize else {
                self.log.log("UDP #\(id): invalid frame length \(frameLen), closing connection")
                client.cancel()
                return
            }

            self.readUDPFrameData(client: client, id: id, frameLen: frameLen)
        }
    }

    private func readUDPFrameData(client: NWConnection, id: Int, frameLen: Int) {
        client.receive(minimumIncompleteLength: frameLen, maximumLength: frameLen) { [weak self] data, _, _, error in
            guard let self = self else { return }
            guard let data = data, data.count >= frameLen, error == nil else {
                self.log.log("UDP #\(id): frame data read failed: \(String(describing: error))")
                client.cancel()
                return
            }

            let bytes = [UInt8](data)

            #if DEBUG
            let hexPrefix = bytes.prefix(20).map { String(format: "%02x", $0) }.joined(separator: " ")
            self.log.log("UDP #\(id): frame data (\(bytes.count)B): \(hexPrefix)")
            #endif

            // hev-socks5 FWD_UDP frame format:
            //   [1 byte][ATYP(1)][ADDR(var)][PORT(2)][payload]
            // ATYP is at byte 1
            guard let addr = self.parseSOCKSAddress(from: bytes, atypOffset: 1) else {
                self.log.log("UDP #\(id): failed to parse UDP frame address")
                self.readUDPFrameLength(client: client, id: id)
                return
            }

            let headerBytes = Array(bytes[0..<addr.headerEndOffset])
            let payload = addr.headerEndOffset < bytes.count ? Data(bytes[addr.headerEndOffset...]) : Data()

            self.statsUDP += 1
            self.log.log("UDP #\(id): dest=\(addr.host):\(addr.port), payload=\(payload.count)B")

            // Block QUIC (UDP 443) to tracked CDNs so video falls back to TLS,
            // where the byte-threshold stream blocker can act.
            if self.filter.shouldBlockUDP(host: addr.host, port: addr.port) == .block {
                self.statsBlocked += 1
                self.log.log("UDP #\(id): QUIC BLOCKED \(addr.host):\(addr.port) (tracked CDN)")
                self.recordEvent(type: .blocked, connId: id, host: addr.host, port: addr.port, detail: "QUIC/UDP 443 blocked (forces TLS fallback)")
                self.readUDPFrameLength(client: client, id: id)
                return
            }

            self.relayUDPDatagram(client: client, id: id, host: addr.host, port: addr.port,
                                   payload: payload, headerBytes: headerBytes)
        }
    }

    private func relayUDPDatagram(client: NWConnection, id: Int, host: String, port: UInt16,
                                   payload: Data, headerBytes: [UInt8]) {
        guard let nwPort = NWEndpoint.Port(rawValue: port) else {
            self.log.log("UDP #\(id): invalid port \(port)")
            self.statsErrors += 1
            self.readUDPFrameLength(client: client, id: id)
            return
        }

        let udp = NWConnection(host: NWEndpoint.Host(host), port: nwPort, using: .udp)

        // Guard against double-continuation from timeout vs completion race
        var completed = false
        let complete: (Data?) -> Void = { [weak self] responseFrame in
            self?.queue.async {
                guard let self = self, !completed else { return }
                completed = true
                udp.cancel()

                if let frame = responseFrame {
                    client.send(content: frame, completion: .contentProcessed { _ in
                        self.readUDPFrameLength(client: client, id: id)
                    })
                } else {
                    self.readUDPFrameLength(client: client, id: id)
                }
            }
        }

        // UDP response timeout
        queue.asyncAfter(deadline: .now() + RinklerConstants.udpRelayTimeout) { [weak self] in
            self?.log.log("UDP #\(id): TIMEOUT for \(host):\(port)")
            complete(nil)
        }

        udp.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                self?.log.log("UDP #\(id): NWConnection ready to \(host):\(port), sending \(payload.count)B")
                udp.send(content: payload, completion: .contentProcessed { error in
                    if let error = error {
                        self?.log.log("UDP #\(id): send FAILED to \(host):\(port): \(error)")
                        complete(nil)
                        return
                    }

                    udp.receiveMessage { respData, context, isComplete, recvError in
                        if let respData = respData, !respData.isEmpty {
                            self?.log.log("UDP #\(id): got \(respData.count)B response from \(host):\(port)")
                            // Snoop DNS answers to learn which IPs belong to
                            // tracked CDNs (needed to block their QUIC traffic).
                            if port == 53, let dns = TrackedIPStore.parseDNSResponse(respData) {
                                self?.filter.recordDNS(host: dns.host, ips: dns.ips)
                            }
                            var frame = headerBytes
                            frame.append(contentsOf: [UInt8](respData))
                            let frameLen = frame.count
                            var framedData: [UInt8] = [UInt8(frameLen >> 8), UInt8(frameLen & 0xFF)]
                            framedData.append(contentsOf: frame)
                            complete(Data(framedData))
                        } else {
                            self?.log.log("UDP #\(id): empty/nil response from \(host):\(port), error=\(String(describing: recvError))")
                            complete(nil)
                        }
                    }
                })

            case .failed(let error):
                self?.log.log("UDP #\(id): NWConnection FAILED to \(host):\(port): \(error)")
                complete(nil)

            case .waiting(let error):
                self?.log.log("UDP #\(id): NWConnection WAITING to \(host):\(port): \(error)")

            default:
                break
            }
        }

        udp.start(queue: queue)
    }

    // MARK: - Target Connection (TCP)

    private func connectToTarget(client: NWConnection, host: String, port: UInt16, id: Int) {
        guard let nwPort = NWEndpoint.Port(rawValue: port) else {
            self.log.log("SOCKS5 #\(id): invalid port \(port)")
            self.statsErrors += 1
            self.activeConnectionCount -= 1
            self.sendSocksError(client: client, reply: 0x05)
            return
        }

        let target = NWConnection(host: NWEndpoint.Host(host), port: nwPort, using: .tcp)

        // Track bytes for diagnostic logging
        let tracker = RelayTracker(id: id, host: host, port: port)
        activeRelays[id] = tracker

        // TCP relay timeout — cancel both sides if idle too long
        let timeout = DispatchWorkItem { [weak self] in
            self?.log.log("SOCKS5 #\(id): relay timeout to \(host):\(port)")
            self?.logRelayEnd(tracker: tracker, reason: "timeout")
            client.cancel()
            target.cancel()
        }
        queue.asyncAfter(deadline: .now() + RinklerConstants.tcpRelayTimeout, execute: timeout)

        target.stateUpdateHandler = { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .ready:
                let reply = self.buildSocksReply(reply: 0x00, atyp: 0x01, addr: [0, 0, 0, 0], port: 0)
                client.send(content: reply, completion: .contentProcessed { error in
                    if error != nil {
                        timeout.cancel()
                        self.logRelayEnd(tracker: tracker, reason: "send-error")
                        client.cancel()
                        target.cancel()
                        return
                    }
                    self.relay(from: client, to: target, tracker: tracker, direction: .upload)
                    self.relay(from: target, to: client, tracker: tracker, direction: .download)
                })

            case .failed(let error):
                timeout.cancel()
                self.log.log("SOCKS5 #\(id): target failed \(host):\(port) — \(error)")
                self.statsErrors += 1
                self.recordEvent(type: .error, connId: id, host: host, port: port, detail: "Target connection failed: \(error.localizedDescription)")
                self.logRelayEnd(tracker: tracker, reason: "target-failed")
                self.sendSocksError(client: client, reply: 0x05)
                target.cancel()

            case .cancelled:
                timeout.cancel()
                self.logRelayEnd(tracker: tracker, reason: "cancelled")
                client.cancel()

            default:
                break
            }
        }

        target.start(queue: queue)
    }

    // MARK: - Relay Byte Tracking

    private enum RelayDirection {
        case upload
        case download
    }

    private class RelayTracker {
        let id: Int
        let host: String
        let port: UInt16
        let startTime = Date()
        var bytesUp: Int = 0
        var bytesDown: Int = 0
        var logged = false
        var sni: String?
        var sniExtracted = false
        var loggedUntracked = false

        init(id: Int, host: String, port: UInt16) {
            self.id = id
            self.host = host
            self.port = port
        }
    }

    private func logRelayEnd(tracker: RelayTracker, reason: String) {
        guard !tracker.logged else { return }
        tracker.logged = true
        activeConnectionCount = max(activeConnectionCount - 1, 0)
        let duration = String(format: "%.1f", Date().timeIntervalSince(tracker.startTime))
        let totalBytes = tracker.bytesUp + tracker.bytesDown
        let sniStr = tracker.sni ?? "n/a"
        log.logConnection("RELAY #\(tracker.id): \(tracker.host):\(tracker.port) SNI=\(sniStr) — \(reason) — \(duration)s — up:\(tracker.bytesUp)B down:\(tracker.bytesDown)B total:\(totalBytes)B (active:\(activeConnectionCount))")

        // Record completed event (unless already recorded as stream-blocked or error)
        if reason != "stream-blocked" && reason != "target-failed" {
            recordEvent(type: .completed, connId: tracker.id, host: tracker.host, port: tracker.port, sni: tracker.sni, detail: "\(reason) — \(duration)s — \(totalBytes)B", bytesDown: tracker.bytesDown)
        }

        // Update domain stats
        let domain = tracker.sni ?? tracker.host
        let current = domainStats[domain] ?? (count: 0, bytes: 0)
        domainStats[domain] = (count: current.count + 1, bytes: current.bytes + totalBytes)

        // Remove from active relays after 5s (so dashboard sees the final state briefly)
        let relayId = tracker.id
        queue.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            self?.activeRelays.removeValue(forKey: relayId)
        }
    }

    // MARK: - TLS SNI Parser

    /// Extracts the SNI (Server Name Indication) from a TLS ClientHello message.
    /// The ClientHello is the first thing the client sends on a TLS connection,
    /// and the SNI extension contains the plaintext domain name.
    private func extractSNI(from data: Data) -> String? {
        let bytes = [UInt8](data)
        // TLS record: [ContentType(1)][Version(2)][Length(2)][Handshake...]
        guard bytes.count >= 5,
              bytes[0] == 0x16,         // ContentType: Handshake
              bytes[1] == 0x03          // TLS major version 3.x
        else { return nil }

        let recordLen = (Int(bytes[3]) << 8) | Int(bytes[4])
        guard bytes.count >= 5 + recordLen else { return nil }

        // Handshake: [Type(1)][Length(3)][ClientHello...]
        let hsStart = 5
        guard bytes.count > hsStart,
              bytes[hsStart] == 0x01    // HandshakeType: ClientHello
        else { return nil }

        // ClientHello body starts at hsStart + 4
        let chStart = hsStart + 4
        // ClientHello: [Version(2)][Random(32)][SessionIDLen(1)][SessionID...]
        guard bytes.count >= chStart + 2 + 32 + 1 else { return nil }

        var offset = chStart + 2 + 32 // skip version + random

        // Session ID
        let sessionIDLen = Int(bytes[offset])
        offset += 1 + sessionIDLen

        // Cipher suites: [Length(2)][...]
        guard bytes.count >= offset + 2 else { return nil }
        let cipherLen = (Int(bytes[offset]) << 8) | Int(bytes[offset + 1])
        offset += 2 + cipherLen

        // Compression methods: [Length(1)][...]
        guard bytes.count >= offset + 1 else { return nil }
        let compLen = Int(bytes[offset])
        offset += 1 + compLen

        // Extensions: [TotalLength(2)][Extension...]
        guard bytes.count >= offset + 2 else { return nil }
        let extTotalLen = (Int(bytes[offset]) << 8) | Int(bytes[offset + 1])
        offset += 2

        let extEnd = min(offset + extTotalLen, bytes.count)

        // Walk extensions looking for SNI (type 0x0000)
        while offset + 4 <= extEnd {
            let extType = (Int(bytes[offset]) << 8) | Int(bytes[offset + 1])
            let extLen = (Int(bytes[offset + 2]) << 8) | Int(bytes[offset + 3])
            offset += 4

            if extType == 0x0000 { // SNI extension
                // SNI extension data: [ListLength(2)][Type(1)][NameLength(2)][Name...]
                guard offset + 5 <= extEnd else { return nil }
                // skip list length (2 bytes)
                let nameType = bytes[offset + 2]
                guard nameType == 0x00 else { return nil } // host_name type
                let nameLen = (Int(bytes[offset + 3]) << 8) | Int(bytes[offset + 4])
                let nameStart = offset + 5
                guard nameStart + nameLen <= bytes.count else { return nil }
                return String(bytes: Array(bytes[nameStart..<(nameStart + nameLen)]), encoding: .utf8)
            }

            offset += extLen
        }

        return nil
    }

    // MARK: - Bidirectional Relay

    private func relay(from source: NWConnection, to destination: NWConnection, tracker: RelayTracker, direction: RelayDirection) {
        source.receive(minimumIncompleteLength: 1, maximumLength: RinklerConstants.relayBufferSize) { [weak self] data, _, isComplete, error in
            guard let self = self else { return }
            if let data = data, !data.isEmpty {
                switch direction {
                case .upload:
                    tracker.bytesUp += data.count
                    // Extract SNI from the first upload packet (TLS ClientHello)
                    if !tracker.sniExtracted {
                        tracker.sniExtracted = true
                        if let sni = self.extractSNI(from: data) {
                            tracker.sni = sni
                            self.log.logConnection("TCP #\(tracker.id): SNI=\(sni) IP=\(tracker.host):\(tracker.port)")
                            TunnelLogger.connectionLog.log("[SNI] \(sni, privacy: .private)")
                            // Learn this IP for QUIC blocking on parallel UDP/443.
                            self.filter.recordSNI(sni, ip: tracker.host)
                        }
                    }
                case .download:
                    tracker.bytesDown += data.count

                    // Stream blocking: per-domain byte thresholds
                    if let sni = tracker.sni {
                        if let threshold = self.filter.streamBlockThreshold(for: sni),
                           tracker.bytesDown > threshold {
                            self.log.log("STREAM BLOCK #\(tracker.id): killed \(sni) at \(tracker.bytesDown)B (threshold: \(threshold)B)")
                            self.recordEvent(type: .streamBlocked, connId: tracker.id, host: tracker.host, port: tracker.port, sni: sni, detail: "Killed at \(tracker.bytesDown)B (threshold: \(threshold)B)", bytesDown: tracker.bytesDown)
                            self.logRelayEnd(tracker: tracker, reason: "stream-blocked")
                            source.cancel()
                            destination.cancel()
                            return
                        }
                        // Log untracked domains receiving large downloads (potential failover)
                        if self.filter.streamBlockThreshold(for: sni) == nil && tracker.bytesDown > 100_000 && !tracker.loggedUntracked {
                            tracker.loggedUntracked = true
                            TunnelLogger.connectionLog.log("[UNTRACKED-LARGE] \(sni, privacy: .private) \(tracker.bytesDown, privacy: .public)B+ (no blocking rule)")
                        }
                    }
                }
                destination.send(content: data, completion: .contentProcessed { sendError in
                    if sendError != nil {
                        self.logRelayEnd(tracker: tracker, reason: "relay-error")
                        source.cancel()
                        destination.cancel()
                        return
                    }
                    if isComplete {
                        self.logRelayEnd(tracker: tracker, reason: "complete")
                        source.cancel()
                        destination.cancel()
                    } else {
                        self.relay(from: source, to: destination, tracker: tracker, direction: direction)
                    }
                })
            } else if isComplete || error != nil {
                self.logRelayEnd(tracker: tracker, reason: isComplete ? "complete" : "error")
                source.cancel()
                destination.cancel()
            }
        }
    }

    // MARK: - SOCKS5 Reply Helpers

    private func sendSocksError(client: NWConnection, reply: UInt8) {
        let data = buildSocksReply(reply: reply, atyp: 0x01, addr: [0, 0, 0, 0], port: 0)
        client.send(content: data, completion: .contentProcessed { _ in
            client.cancel()
        })
    }

    private static func memoryUsageMB() -> String {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        if result == KERN_SUCCESS {
            return String(format: "%.1f", Double(info.resident_size) / 1_048_576)
        }
        return "?"
    }

    private func buildSocksReply(reply: UInt8, atyp: UInt8, addr: [UInt8], port: UInt16) -> Data {
        var response: [UInt8] = [
            0x05,   // VER
            reply,  // REP
            0x00,   // RSV
            atyp    // ATYP
        ]
        response.append(contentsOf: addr)
        response.append(UInt8(port >> 8))
        response.append(UInt8(port & 0xFF))
        return Data(response)
    }
}
