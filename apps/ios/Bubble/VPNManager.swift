import Foundation
import Combine
@preconcurrency import NetworkExtension
import SwiftUI

@MainActor
final class VPNManager: ObservableObject {
    @Published var vpnStatus: NEVPNStatus = .disconnected
    @Published private(set) var statusLog: [String] = []
    @Published var tunnelLog: String = "(no logs yet)"
    @Published private(set) var isPreparingProfile = false

    private var manager: NETunnelProviderManager?
    private var statusObserver: NSObjectProtocol?

    deinit {
        if let observer = statusObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Setup

    func setup() {
        appendLog("App launched")
        loadVPNPreferences(startAfterLoad: false)
    }

    // MARK: - Status Log (bounded)

    func appendLog(_ msg: String) {
        let ts = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        statusLog.append("[\(ts)] \(msg)")
        if statusLog.count > BubbleConstants.maxStatusLogEntries {
            statusLog.removeFirst(statusLog.count - BubbleConstants.maxStatusLogEntries)
        }
    }

    // MARK: - Tunnel Extension Log

    func refreshTunnelLog() {
        tunnelLog = TunnelLogReader.readLog()
    }

    // MARK: - VPN Lifecycle

    private func loadVPNPreferences(startAfterLoad: Bool) {
        appendLog("Loading VPN preferences...")
        NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, error in
            Task { @MainActor [weak self] in
                guard let self = self else { return }

                if let error = error {
                    self.appendLog("ERROR loading prefs: \(error.localizedDescription)")
                    return
                }

                if let existingManagers = managers, !existingManagers.isEmpty {
                    let mgr = existingManagers[0]
                    self.manager = mgr
                    self.vpnStatus = mgr.connection.status
                    self.appendLog("Found existing profile. Status: \(self.statusString)")
                    self.appendLog("Bundle ID: \((mgr.protocolConfiguration as? NETunnelProviderProtocol)?.providerBundleIdentifier ?? "nil")")
                    self.observeStatusChanges(for: mgr)
                    if startAfterLoad && mgr.connection.status != .connected && mgr.connection.status != .connecting {
                        self.startVPN()
                    }
                } else {
                    self.appendLog("No VPN profile configured yet")
                    if startAfterLoad {
                        self.createVPNProfile(startAfterSave: true)
                    }
                }
            }
        }
    }

    private func observeStatusChanges(for mgr: NETunnelProviderManager) {
        if let existing = statusObserver {
            NotificationCenter.default.removeObserver(existing)
        }

        statusObserver = NotificationCenter.default.addObserver(
            forName: .NEVPNStatusDidChange,
            object: mgr.connection,
            queue: .main
        ) { [weak self, weak mgr] _ in
            guard let mgr = mgr else { return }
            let newStatus = mgr.connection.status
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.vpnStatus = newStatus
                self.appendLog("VPN status -> \(Self.statusString(for: newStatus))")

                if newStatus == .connected || newStatus == .disconnected {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                        self?.refreshTunnelLog()
                    }
                }
            }
        }
    }

    private func createVPNProfile(startAfterSave: Bool) {
        guard !isPreparingProfile else { return }
        isPreparingProfile = true
        appendLog("No VPN profile found, creating one...")
        let newManager = NETunnelProviderManager()
        let proto = NETunnelProviderProtocol()
        proto.providerBundleIdentifier = BubbleConstants.tunnelBundleID
        proto.serverAddress = BubbleConstants.vpnServerAddress
        newManager.protocolConfiguration = proto
        newManager.localizedDescription = BubbleConstants.vpnDescription

        newManager.saveToPreferences { [weak self] error in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.isPreparingProfile = false
                if let error = error {
                    self.appendLog("ERROR saving profile: \(error.localizedDescription)")
                    return
                }
                self.appendLog("Profile saved. Reloading...")
                self.loadVPNPreferences(startAfterLoad: startAfterSave)
            }
        }
    }

    func toggleVPN() {
        guard let manager = self.manager else {
            startVPN()
            return
        }

        if manager.connection.status == .connected || manager.connection.status == .connecting {
            stopVPN()
        } else {
            startVPN()
        }
    }

    func startVPN() {
        guard let manager = self.manager else {
            appendLog("Preparing VPN profile...")
            createVPNProfile(startAfterSave: true)
            return
        }

        appendLog("Starting VPN...")

        manager.loadFromPreferences { [weak self] error in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if let error = error {
                    self.appendLog("ERROR loading: \(error.localizedDescription)")
                    return
                }

                manager.isEnabled = true
                manager.saveToPreferences { [weak self] error in
                    Task { @MainActor [weak self] in
                        guard let self = self else { return }
                        if let error = error {
                            self.appendLog("ERROR saving: \(error.localizedDescription)")
                            return
                        }

                        do {
                            self.appendLog("Starting VPN tunnel...")
                            try manager.connection.startVPNTunnel()
                            self.appendLog("startVPNTunnel() called successfully")
                        } catch {
                            let nsError = error as NSError
                            self.appendLog("ERROR starting: \(error.localizedDescription)")
                            self.appendLog("Error details: \(nsError.domain) code \(nsError.code)")
                        }
                    }
                }
            }
        }
    }

    private func stopVPN() {
        guard let manager = self.manager else {
            appendLog("ERROR: Manager not ready")
            return
        }
        appendLog("Stopping VPN tunnel...")
        manager.connection.stopVPNTunnel()
    }

    // MARK: - Display Helpers

    var statusString: String {
        Self.statusString(for: vpnStatus)
    }

    static func statusString(for status: NEVPNStatus) -> String {
        switch status {
        case .invalid: return "Invalid"
        case .disconnected: return "Disconnected"
        case .connecting: return "Connecting..."
        case .connected: return "Connected"
        case .reasserting: return "Reasserting..."
        case .disconnecting: return "Disconnecting..."
        @unknown default: return "Unknown"
        }
    }

    static func statusColor(for status: NEVPNStatus) -> Color {
        switch status {
        case .connected: return .green
        case .connecting, .reasserting: return .orange
        case .disconnecting: return .yellow
        default: return .red
        }
    }
}
