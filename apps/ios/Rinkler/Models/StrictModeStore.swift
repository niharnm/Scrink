import Foundation
import Combine

/// Strict Mode — the hardest tier above Commitment Mode.
///
/// Once armed for a window, the user cannot weaken anything from inside the app
/// (every off-switch is disabled) and — once the Family Controls entitlement is
/// live — cannot delete any app on the device (`denyAppRemoval`) and the chosen
/// apps are shielded at the OS level. The one honest escape is iOS Settings →
/// Screen Time. There is deliberately no in-app disarm.
///
/// This file holds NO Family Controls symbols so it compiles and runs today; the
/// OS-level enforcement is delegated to `StrictModeShieldController` /
/// `StrictModeActivityScheduler`, which no-op until the entitlement + Screen Time
/// authorization are present.
@MainActor
final class StrictModeStore: ObservableObject {
    @Published private(set) var isActive: Bool = false
    @Published private(set) var endDate: Date?
    @Published var lockAppRemoval: Bool

    private let defaults = UserDefaults(suiteName: RinklerConstants.appGroupID)

    private weak var vpn: VPNManager?
    private weak var commitment: CommitmentStore?
    private weak var screenTime: ScreenTimeManager?
    private let shield = StrictModeShieldController()
    private let scheduler = StrictModeActivityScheduler()

    private var ticker: AnyCancellable?

    /// Whether Strict Mode is active right now, read straight from shared storage.
    /// Used by stores (FocusSystemStore, DomainThresholdsStore) for defense in
    /// depth so non-UI code paths can't weaken limits while strict.
    static var isActivePersisted: Bool {
        let d = UserDefaults(suiteName: RinklerConstants.appGroupID)
        guard d?.bool(forKey: RinklerConstants.strictModeEnabledKey) == true else { return false }
        let end = d?.double(forKey: RinklerConstants.strictModeEndEpochKey) ?? 0
        return end == 0 || Date().timeIntervalSince1970 < end
    }

    init() {
        lockAppRemoval = defaults?.bool(forKey: RinklerConstants.strictModeLockAppRemovalKey) ?? true
        deriveFromStorage()
    }

    func configure(vpn: VPNManager, commitment: CommitmentStore, screenTime: ScreenTimeManager) {
        self.vpn = vpn
        self.commitment = commitment
        self.screenTime = screenTime
        // Re-apply OS enforcement on launch if a window is still open (e.g. the
        // app was killed and relaunched mid-window).
        if isActive { applyEnforcement() }
    }

    // MARK: - Derived state

    private func deriveFromStorage() {
        let enabled = defaults?.bool(forKey: RinklerConstants.strictModeEnabledKey) ?? false
        let end = defaults?.double(forKey: RinklerConstants.strictModeEndEpochKey) ?? 0
        endDate = end > 0 ? Date(timeIntervalSince1970: end) : nil
        isActive = enabled && (end == 0 || Date().timeIntervalSince1970 < end)
        if isActive { startTicker() } else if enabled { clearStorage() }
    }

    var remainingSeconds: Int {
        guard let endDate else { return 0 }
        return max(0, Int(endDate.timeIntervalSinceNow))
    }

    var remainingLabel: String {
        let s = remainingSeconds
        let h = s / 3600, m = (s % 3600) / 60
        if h > 0 { return "\(h)h \(m)m left" }
        if m > 0 { return "\(m)m left" }
        return "<1m left"
    }

    var endLabel: String {
        guard let endDate else { return "" }
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: endDate)
    }

    // MARK: - Arm / end

    /// Arms Strict Mode for `duration` seconds. There is no in-app disarm.
    func arm(duration: TimeInterval, lockAppRemoval: Bool) {
        let now = Date()
        let end = now.addingTimeInterval(duration)
        self.lockAppRemoval = lockAppRemoval

        defaults?.set(true, forKey: RinklerConstants.strictModeEnabledKey)
        defaults?.set(now.timeIntervalSince1970, forKey: RinklerConstants.strictModeStartEpochKey)
        defaults?.set(end.timeIntervalSince1970, forKey: RinklerConstants.strictModeEndEpochKey)
        defaults?.set(lockAppRemoval, forKey: RinklerConstants.strictModeLockAppRemovalKey)
        appendArmedReceipt(now)

        endDate = end
        isActive = true

        // Strict is a superset of Commitment: force the gentler tier on and turn
        // protection on so there's a real block in place.
        commitment?.isEnabled = true
        vpn?.startVPN()

        applyEnforcement()
        startTicker()
    }

    /// Ends the window (timer reached, or window cleared by the monitor extension).
    func end() {
        clearStorage()
        isActive = false
        endDate = nil
        ticker?.cancel(); ticker = nil
        shield.clear()
        scheduler.stop()
        // Leave Commitment Mode as the user had it — strict is a temporary
        // escalation, not a permanent change to their gentler settings.
    }

    /// Called on launch, on foreground, and by the in-app ticker.
    func tickIfExpired() {
        guard isActive, let endDate else { return }
        if Date() >= endDate { end() }
    }

    // MARK: - Enforcement (no-ops until entitlement + Screen Time auth)

    private func applyEnforcement() {
        guard screenTime?.isAuthorized == true else { return }
        shield.apply(lockAppRemoval: lockAppRemoval)
        if let endDate { scheduler.start(until: endDate) }
    }

    // MARK: - Internals

    private func startTicker() {
        ticker?.cancel()
        ticker = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                self.objectWillChange.send()   // refresh countdown UIs
                self.tickIfExpired()
            }
    }

    private func clearStorage() {
        defaults?.set(false, forKey: RinklerConstants.strictModeEnabledKey)
        defaults?.removeObject(forKey: RinklerConstants.strictModeStartEpochKey)
        defaults?.removeObject(forKey: RinklerConstants.strictModeEndEpochKey)
    }

    private func appendArmedReceipt(_ date: Date) {
        var receipts: [Date] = []
        if let data = defaults?.data(forKey: RinklerConstants.strictModeArmedReceiptsKey),
           let decoded = try? JSONDecoder().decode([Date].self, from: data) {
            receipts = decoded
        }
        receipts.append(date)
        if receipts.count > 100 { receipts.removeFirst(receipts.count - 100) }
        if let data = try? JSONEncoder().encode(receipts) {
            defaults?.set(data, forKey: RinklerConstants.strictModeArmedReceiptsKey)
        }
    }
}
