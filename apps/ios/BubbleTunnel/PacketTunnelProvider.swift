import NetworkExtension
import Tun2SocksKit

class PacketTunnelProvider: NEPacketTunnelProvider {

    private let log = TunnelLogger.shared
    private var proxyServer: SOCKSProxyServer?
    private let filter = ReelsBlockFilter()

    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        log.clear()
        log.log("========== TUNNEL STARTING ==========")
        log.log("Bundle ID: \(Bundle.main.bundleIdentifier ?? "nil")")
        log.log("Process ID: \(ProcessInfo.processInfo.processIdentifier)")

        // Step 1: Network settings
        log.log("STEP 1: Setting tunnel network settings...")

        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: BubbleConstants.tunnelRemoteAddress)
        let ipv4 = NEIPv4Settings(
            addresses: [BubbleConstants.tunnelLocalAddress],
            subnetMasks: [BubbleConstants.tunnelSubnetMask]
        )
        ipv4.includedRoutes = [NEIPv4Route.default()]
        settings.ipv4Settings = ipv4
        let dns = NEDNSSettings(servers: BubbleConstants.dnsServers)
        settings.dnsSettings = dns
        settings.mtu = BubbleConstants.mtu

        setTunnelNetworkSettings(settings) { error in
            if let error = error {
                self.log.log("STEP 1 FAILED: \(error.localizedDescription)")
                completionHandler(error)
                return
            }
            self.log.log("STEP 1 SUCCESS: Network settings applied, utun created")

            // Step 2: Start SOCKS5 proxy
            self.log.log("STEP 2: Starting SOCKS5 proxy...")
            let proxy = SOCKSProxyServer(filter: self.filter)
            self.proxyServer = proxy

            proxy.start { startError in
                if let startError = startError {
                    self.log.log("STEP 2 FAILED: Proxy error: \(startError.localizedDescription)")
                    completionHandler(startError)
                    return
                }

                let proxyPort = proxy.actualPort
                self.log.log("STEP 2 SUCCESS: SOCKS5 proxy is ready on port \(proxyPort)")

                // Step 3: Start tun2socks
                self.log.log("STEP 3: Starting tun2socks...")
                let config = """
                tunnel:
                  mtu: \(BubbleConstants.mtu)
                socks5:
                  port: \(proxyPort)
                  address: \(BubbleConstants.socksBindAddress)
                misc:
                  task-stack-size: \(BubbleConstants.tun2socksTaskStackSize)
                  tcp-buffer-size: \(BubbleConstants.tun2socksTCPBufferSize)
                  connect-timeout: \(BubbleConstants.tun2socksConnectTimeout)
                  read-write-timeout: \(BubbleConstants.tun2socksReadWriteTimeout)
                  log-level: info
                """
                self.log.log("STEP 3: tun2socks config:\n\(config)")

                Socks5Tunnel.run(withConfig: .string(content: config)) { exitCode in
                    self.log.log("STEP 3: tun2socks EXITED with code \(exitCode)")
                    if exitCode == -1 {
                        self.log.log("STEP 3: exit code -1 means utun fd was NOT found!")
                    }
                }

                DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
                    let stats = Socks5Tunnel.stats
                    self.log.log("STEP 3 CHECK: tun2socks stats after 1s — up: \(stats.up.packets) pkts, down: \(stats.down.packets) pkts")
                }

                self.log.log("STEP 4: Calling completionHandler(nil) — tunnel should show Connected")
                completionHandler(nil)
                self.log.log("========== TUNNEL STARTED ==========")
            }
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        let reasonName: String
        switch reason {
        case .none: reasonName = "none"
        case .userInitiated: reasonName = "userInitiated"
        case .providerFailed: reasonName = "providerFailed"
        case .noNetworkAvailable: reasonName = "noNetworkAvailable"
        case .unrecoverableNetworkChange: reasonName = "unrecoverableNetworkChange"
        case .providerDisabled: reasonName = "providerDisabled"
        case .authenticationCanceled: reasonName = "authenticationCanceled"
        case .configurationFailed: reasonName = "configurationFailed"
        case .idleTimeout: reasonName = "idleTimeout"
        case .configurationDisabled: reasonName = "configurationDisabled"
        case .configurationRemoved: reasonName = "configurationRemoved"
        case .superceded: reasonName = "superceded"
        case .userLogout: reasonName = "userLogout"
        case .userSwitch: reasonName = "userSwitch"
        case .connectionFailed: reasonName = "connectionFailed"
        case .sleep: reasonName = "sleep"
        case .appUpdate: reasonName = "appUpdate"
        default: reasonName = "unknown(\(reason.rawValue))"
        }
        log.log("========== TUNNEL STOPPING (reason: \(reasonName) / \(reason.rawValue)) ==========")
        let stats = Socks5Tunnel.stats
        log.log("Final stats — Up: \(stats.up.packets) pkts / \(stats.up.bytes) bytes, Down: \(stats.down.packets) pkts / \(stats.down.bytes) bytes")
        log.log("Memory: \(Self.memoryUsageMB()) MB")
        Socks5Tunnel.quit()
        proxyServer?.stop()
        proxyServer = nil
        completionHandler()
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

    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        let message = String(data: messageData, encoding: .utf8) ?? "unknown"
        log.log("App message: \(message)")
        if message == "ping" {
            let stats = Socks5Tunnel.stats
            let reply = "pong — up: \(stats.up.packets) pkts, down: \(stats.down.packets) pkts"
            completionHandler?(reply.data(using: .utf8))
        } else {
            completionHandler?(nil)
        }
    }
}
