import Foundation
import Combine

// MARK: - Derived state + supporting types

/// What Automatic Mode concluded from your health trends. Always honest: this is
/// a heuristic, never a medical reading, and `reasons` is shown verbatim.
struct DerivedState: Codable {
    enum Tier: String, Codable { case calm, mildlyTight, tight }
    var tier: Tier
    var reasons: [String]
    var confidence: Double
    var evaluatedAt: Date

    static let calm = DerivedState(tier: .calm, reasons: [], confidence: 0, evaluatedAt: .distantPast)
}

enum AutoSensitivity: String, CaseIterable, Identifiable, Codable {
    case soft, normal, strict
    var id: String { rawValue }
    var title: String {
        switch self {
        case .soft: return "Soft"
        case .normal: return "Normal"
        case .strict: return "Strict"
        }
    }
    /// How many MADs from baseline counts as a real change (lower = more sensitive).
    var k: Double {
        switch self {
        case .soft: return 2.0
        case .normal: return 1.5
        case .strict: return 1.0
        }
    }
    /// Soft/Normal need both stress signals to agree; Strict fires on either.
    var requireBothStressSignals: Bool { self != .strict }
}

struct AutoModeLogEntry: Codable, Identifiable {
    var id: UUID
    var at: Date
    var action: String      // "Tightened" / "Reverted"
    var tier: String
    var reasons: [String]
}

/// The brain: maps a `DerivedState` to a limit policy with hysteresis + cooldown +
/// dwell (so a single noisy sample can't toggle your limits), and enforces it by
/// snapshotting then writing the EXISTING tunnel knobs (domain thresholds + the
/// per-platform enable flags) — the same approach `FocusSessionStore` uses. When
/// the Family Controls entitlement is live it also drives `ShieldController` for
/// true no-tap background enforcement.
@MainActor
final class AutoModeEngine: ObservableObject {
    @Published var enabled: Bool {
        didSet { defaults?.set(enabled, forKey: RinklerConstants.autoModeEnabledKey) }
    }
    @Published var sensitivity: AutoSensitivity {
        didSet { defaults?.set(sensitivity.rawValue, forKey: RinklerConstants.autoModeSensitivityKey) }
    }
    @Published private(set) var lastState: DerivedState = .calm
    @Published private(set) var log: [AutoModeLogEntry] = []
    @Published private(set) var isApplied: Bool = false

    enum Trigger { case foreground, observer, scheduled, manual }

    private weak var health: HealthManager?
    private weak var screenTime: ScreenTimeManager?
    private let shield = ShieldController()
    private let defaults = UserDefaults(suiteName: RinklerConstants.appGroupID)

    private let minActionInterval: TimeInterval = 30 * 60
    private let minDwell: TimeInterval = 45 * 60
    private let activityCutoffHour = 17

    private var tightenStreak = 0
    private var calmStreak = 0

    init() {
        enabled = defaults?.bool(forKey: RinklerConstants.autoModeEnabledKey) ?? false
        sensitivity = AutoSensitivity(rawValue: defaults?.string(forKey: RinklerConstants.autoModeSensitivityKey) ?? "") ?? .normal
        isApplied = defaults?.data(forKey: RinklerConstants.autoModeActiveSnapshotKey) != nil
        loadLog()
        loadState()
    }

    func configure(health: HealthManager, screenTime: ScreenTimeManager) {
        self.health = health
        self.screenTime = screenTime
    }

    // MARK: - Evaluation

    func evaluate(trigger: Trigger) async {
        guard enabled, let health, health.isAuthorized else { return }

        // Don't fight a manual focus session or Strict Mode — they're already in
        // charge. Resume on their own evaluation later.
        if defaults?.data(forKey: "activeFocusSession") != nil { return }
        if StrictModeStore.isActivePersisted { return }

        // Cooldown (manual taps bypass it).
        if trigger != .manual, let last = defaults?.object(forKey: RinklerConstants.autoModeLastEvalKey) as? Date,
           Date().timeIntervalSince(last) < minActionInterval { return }
        defaults?.set(Date(), forKey: RinklerConstants.autoModeLastEvalKey)

        // Refresh baseline at most once/day.
        var baseline = health.cachedBaseline()
        if baseline.computedAt.timeIntervalSinceNow < -24 * 60 * 60 || baseline.sampleDays == 0 {
            baseline = await health.recomputeBaseline()
        }
        let readings = await health.latestReadings()
        let state = classify(readings: readings, baseline: baseline)
        lastState = state
        saveState(state)

        // Hysteresis.
        if state.tier != .calm {
            tightenStreak += 1; calmStreak = 0
        } else {
            calmStreak += 1; tightenStreak = 0
        }

        if state.tier != .calm, tightenStreak >= 2, !isApplied {
            apply(state)
        } else if state.tier == .calm, calmStreak >= 2, isApplied, dwellElapsed {
            revert()
        }
    }

    // MARK: - Heuristic

    private func classify(readings: HealthReadings, baseline: HealthBaseline) -> DerivedState {
        // Cold start: don't act until there's a real baseline.
        guard baseline.sampleDays >= 3 else {
            return DerivedState(tier: .calm,
                                reasons: ["Building your baseline (\(baseline.sampleDays)/\(HealthManager.baselineDays) days)"],
                                confidence: 0, evaluatedAt: Date())
        }

        var reasons: [String] = []
        let k = sensitivity.k
        var expected = 0, present = 0

        // Stress: HRV drop + resting-HR rise vs baseline.
        var hrvLow = false, rhrHigh = false
        expected += 1
        if let hrv = readings.hrvSDNN, let med = baseline.hrvMedian, let m = baseline.hrvMAD, m > 0 {
            present += 1
            if hrv < med - k * m { hrvLow = true; reasons.append("HRV below your baseline") }
        }
        expected += 1
        if let rhr = readings.restingHR, let med = baseline.restingHRMedian, let m = baseline.restingHRMAD, m > 0 {
            present += 1
            if rhr > med + k * m { rhrHigh = true; reasons.append("Resting heart rate elevated") }
        }
        let stressed = sensitivity.requireBothStressSignals ? (hrvLow && rhrHigh) : (hrvLow || rhrHigh)

        // Low activity — only meaningful later in the day.
        var moveLow = false
        let hour = Calendar.current.component(.hour, from: Date())
        if hour >= activityCutoffHour {
            expected += 1
            if let move = readings.moveKcal, let med = baseline.moveMedian, med > 0 {
                present += 1
                if move < med * 0.5 { moveLow = true; reasons.append("Move ring low for this time of day") }
            }
            if let steps = readings.steps, let med = baseline.stepsMedian, med > 0 {
                if steps < med * 0.5 {
                    if !moveLow { reasons.append("Steps low for this time of day") }
                    moveLow = true
                }
            }
        }

        let confidence = expected > 0 ? Double(present) / Double(expected) : 0
        guard confidence >= 0.5 else {
            return DerivedState(tier: .calm, reasons: ["Not enough health data yet"],
                                confidence: confidence, evaluatedAt: Date())
        }

        let tier: DerivedState.Tier
        if stressed && moveLow { tier = .tight }
        else if stressed || moveLow { tier = .mildlyTight }
        else { tier = .calm }

        return DerivedState(tier: tier, reasons: tier == .calm ? ["Looking calm"] : reasons,
                            confidence: confidence, evaluatedAt: Date())
    }

    // MARK: - Apply / revert (snapshot the existing tunnel knobs)

    private func apply(_ state: DerivedState) {
        let snapshot = AutoSnapshot(thresholds: loadThresholds(), enabled: loadEnabled(),
                                    appliedAt: Date(), tier: state.tier.rawValue)
        if let data = try? JSONEncoder().encode(snapshot) {
            defaults?.set(data, forKey: RinklerConstants.autoModeActiveSnapshotKey)
        }

        let bytes = state.tier == .tight ? 0 : (512 * 1024)
        var thresholds = loadThresholds()
        for d in RinklerConstants.instagramTrackedDomains + RinklerConstants.tiktokTrackedDomains {
            thresholds[d] = bytes
        }
        saveThresholds(thresholds)
        defaults?.set(true, forKey: RinklerConstants.blockInstagramShortVideoEnabledKey)
        defaults?.set(true, forKey: RinklerConstants.blockTikTokShortVideoEnabledKey)

        // Phase 2: silent whole-app shield from background (entitlement-gated).
        if screenTime?.isAuthorized == true, defaults?.bool(forKey: RinklerConstants.autoModeShieldEnabledKey) == true {
            shield.apply()
        }

        isApplied = true
        appendLog(action: "Tightened", tier: state.tier.rawValue, reasons: state.reasons)
    }

    private func revert() {
        if let data = defaults?.data(forKey: RinklerConstants.autoModeActiveSnapshotKey),
           let snap = try? JSONDecoder().decode(AutoSnapshot.self, from: data) {
            saveThresholds(snap.thresholds)
            for (key, value) in snap.enabled { defaults?.set(value, forKey: key) }
        }
        defaults?.removeObject(forKey: RinklerConstants.autoModeActiveSnapshotKey)
        shield.clear()
        isApplied = false
        appendLog(action: "Reverted", tier: "calm", reasons: ["Signals back to normal"])
    }

    private var dwellElapsed: Bool {
        guard let data = defaults?.data(forKey: RinklerConstants.autoModeActiveSnapshotKey),
              let snap = try? JSONDecoder().decode(AutoSnapshot.self, from: data) else { return true }
        return Date().timeIntervalSince(snap.appliedAt) >= minDwell
    }

    // MARK: - Snapshot type + knob persistence (mirrors FocusSessionStore)

    private struct AutoSnapshot: Codable {
        let thresholds: [String: Int]
        let enabled: [String: Bool]
        let appliedAt: Date
        let tier: String
    }

    private func loadThresholds() -> [String: Int] {
        guard let data = defaults?.data(forKey: RinklerConstants.domainThresholdsKey),
              let dict = try? JSONDecoder().decode([String: Int].self, from: data) else {
            return RinklerConstants.defaultDomainThresholds
        }
        return RinklerConstants.defaultDomainThresholds.merging(dict) { _, saved in saved }
    }

    private func saveThresholds(_ thresholds: [String: Int]) {
        guard let data = try? JSONEncoder().encode(thresholds) else { return }
        defaults?.set(data, forKey: RinklerConstants.domainThresholdsKey)
    }

    private func loadEnabled() -> [String: Bool] {
        [
            RinklerConstants.blockInstagramShortVideoEnabledKey:
                defaults?.bool(forKey: RinklerConstants.blockInstagramShortVideoEnabledKey) ?? true,
            RinklerConstants.blockTikTokShortVideoEnabledKey:
                defaults?.bool(forKey: RinklerConstants.blockTikTokShortVideoEnabledKey) ?? true,
        ]
    }

    // MARK: - Log + state persistence

    private func appendLog(action: String, tier: String, reasons: [String]) {
        let entry = AutoModeLogEntry(id: UUID(), at: Date(), action: action, tier: tier, reasons: reasons)
        log.insert(entry, at: 0)
        if log.count > 100 { log.removeLast(log.count - 100) }
        if let data = try? JSONEncoder().encode(log) {
            defaults?.set(data, forKey: RinklerConstants.autoModeLogKey)
        }
    }

    private func loadLog() {
        guard let data = defaults?.data(forKey: RinklerConstants.autoModeLogKey),
              let decoded = try? JSONDecoder().decode([AutoModeLogEntry].self, from: data) else { return }
        log = decoded
    }

    private func saveState(_ state: DerivedState) {
        if let data = try? JSONEncoder().encode(state) {
            defaults?.set(data, forKey: RinklerConstants.autoModeStateKey)
        }
    }

    private func loadState() {
        guard let data = defaults?.data(forKey: RinklerConstants.autoModeStateKey),
              let decoded = try? JSONDecoder().decode(DerivedState.self, from: data) else { return }
        lastState = decoded
    }
}
