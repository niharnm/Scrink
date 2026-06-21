import Foundation
import Combine

// MARK: - Strictness

/// How hard Rinkler holds the line during a focus session. Each level maps to a
/// real byte threshold applied to the selected platforms' video domains, so the
/// choice has a concrete effect on the packet tunnel rather than being cosmetic.
enum FocusStrictness: String, Codable, CaseIterable, Identifiable {
    case gentle
    case focused
    case deep

    var id: String { rawValue }

    var title: String {
        switch self {
        case .gentle: return "Gentle"
        case .focused: return "Focused"
        case .deep: return "Deep"
        }
    }

    var tagline: String {
        switch self {
        case .gentle: return "Only the heaviest feeds get interrupted. Stop whenever."
        case .focused: return "The everyday setting. Interrupts short-video streams."
        case .deep: return "Holds firm. The session can't be ended early."
        }
    }

    var icon: String {
        switch self {
        case .gentle: return "leaf"
        case .focused: return "scope"
        case .deep: return "lock.shield"
        }
    }

    /// Byte threshold written to each selected domain. `0` means block all
    /// tracked video; a higher number only interrupts the largest streams.
    var thresholdBytes: Int {
        switch self {
        case .gentle: return 1_572_864          // 1.5 MB — only the heaviest
        case .focused: return 512 * 1024        // 0.5 MB — project default
        case .deep: return 0                    // block all tracked video
        }
    }

    /// Whether the user can end the session before the timer runs out. Deep
    /// sessions lock the in-app stop button (see the honest caveat in the UI:
    /// iOS Settings can still disable the VPN — Rinkler can't override the OS).
    var allowsEarlyStop: Bool { self != .deep }
}

// MARK: - Platform target

/// A short-video surface Rinkler can actually act on at the tunnel layer.
/// Deliberately limited to Instagram and TikTok — the README documents why
/// YouTube/Reels/etc. are not offered as section-only blockers.
enum FocusPlatform: String, Codable, CaseIterable, Identifiable {
    case instagram
    case tiktok

    var id: String { rawValue }

    var title: String {
        switch self {
        case .instagram: return "Instagram"
        case .tiktok: return "TikTok"
        }
    }

    /// Matches the icon asset / `SocialMediaIcon` platform key.
    var iconKey: String { rawValue }

    var domains: [String] {
        switch self {
        case .instagram: return RinklerConstants.instagramTrackedDomains
        case .tiktok: return RinklerConstants.tiktokTrackedDomains
        }
    }

    var enabledKey: String {
        switch self {
        case .instagram: return RinklerConstants.blockInstagramShortVideoEnabledKey
        case .tiktok: return RinklerConstants.blockTikTokShortVideoEnabledKey
        }
    }
}

// MARK: - Active session

/// The session currently running. Persisted to the App Group so it survives the
/// app being backgrounded or relaunched mid-session, and carries a snapshot of
/// the prior filter config so it can be restored cleanly when the session ends.
struct ActiveFocusSession: Codable {
    let id: UUID
    let startedAt: Date
    let plannedDuration: TimeInterval   // 0 == open-ended
    let strictness: FocusStrictness
    let platforms: [FocusPlatform]
    let label: String
    let baselineInterrupted: Int

    // Snapshot of config to restore on end.
    let priorThresholds: [String: Int]
    let priorEnabled: [String: Bool]
    let priorVPNConnected: Bool

    var endsAt: Date? {
        plannedDuration > 0 ? startedAt.addingTimeInterval(plannedDuration) : nil
    }
}

// MARK: - Completed record

struct FocusSessionRecord: Codable, Identifiable {
    let id: UUID
    let startedAt: Date
    let endedAt: Date
    let strictness: FocusStrictness
    let platforms: [FocusPlatform]
    let label: String
    let distractionsInterrupted: Int
    let completedFullDuration: Bool

    var durationSeconds: TimeInterval { endedAt.timeIntervalSince(startedAt) }
    var protectedMinutes: Int { Int((durationSeconds / 60).rounded()) }
}

// MARK: - Store

/// Owns the focus-session lifecycle: applying strictness to the real tunnel
/// filters, timing the session, persisting history, and deriving the home
/// screen's hero numbers. All numbers shown to the user are real — focused time
/// is measured wall-clock, distractions are read from the tunnel's own blocked
/// counter — so nothing here is fabricated.
@MainActor
final class FocusSessionStore: ObservableObject {
    @Published private(set) var active: ActiveFocusSession?
    @Published private(set) var records: [FocusSessionRecord] = []
    /// Live interrupted-stream count for the running session (baseline-adjusted).
    @Published private(set) var liveDistractions: Int = 0
    @Published private(set) var lastCompleted: FocusSessionRecord?

    private let defaults = UserDefaults(suiteName: RinklerConstants.appGroupID)
    private let recordsKey = "focusSessionRecords"
    private let activeKey = "activeFocusSession"

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private let statsDecoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private let statsFileURL: URL? = FileManager.default
        .containerURL(forSecurityApplicationGroupIdentifier: RinklerConstants.appGroupID)?
        .appendingPathComponent(RinklerConstants.statsFileName)

    init() {
        load()
        refreshLiveDistractions()
    }

    // MARK: Derived home stats

    var isRunning: Bool { active != nil }

    private var todayRecords: [FocusSessionRecord] {
        let cal = Calendar.current
        return records.filter { cal.isDateInToday($0.startedAt) }
    }

    /// Total focused seconds today (completed sessions + any live session).
    var todayFocusSeconds: TimeInterval {
        var total = todayRecords.reduce(0) { $0 + $1.durationSeconds }
        if let active { total += Date().timeIntervalSince(active.startedAt) }
        return total
    }

    /// Distractions interrupted today (completed + live).
    var todayDistractions: Int {
        todayRecords.reduce(0) { $0 + $1.distractionsInterrupted } + (active != nil ? liveDistractions : 0)
    }

    var sessionsToday: Int { todayRecords.count + (active != nil ? 1 : 0) }

    /// Consecutive days (counting back from today) with at least one session.
    var streak: Int {
        let cal = Calendar.current
        let days = Set(records.map { cal.startOfDay(for: $0.startedAt) })
        guard !days.isEmpty else { return active != nil ? 1 : 0 }
        var count = 0
        var day = cal.startOfDay(for: Date())
        // Allow the streak to "start" today even if today has no record yet but
        // yesterday did.
        if !days.contains(day) {
            if let yesterday = cal.date(byAdding: .day, value: -1, to: day), days.contains(yesterday) {
                day = yesterday
            } else {
                return active != nil ? 1 : 0
            }
        }
        while days.contains(day) {
            count += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return count
    }

    /// Background "clarity" for the living sky: brighter as the user focuses.
    var skyClarity: Double {
        var c = 0.18
        if active != nil { c += 0.45 }
        c += min(Double(streak) * 0.06, 0.3)
        return min(c, 1.0)
    }

    // MARK: Lifecycle

    /// Starts a session: snapshots current filter config, applies the chosen
    /// strictness to the selected platforms, and records the baseline blocked
    /// count. The caller is responsible for starting the VPN tunnel.
    func start(platforms: [FocusPlatform], strictness: FocusStrictness,
               duration: TimeInterval, label: String, vpnConnected: Bool) {
        guard active == nil else { return }
        let targets = platforms.isEmpty ? FocusPlatform.allCases : platforms

        let priorThresholds = loadThresholds()
        var priorEnabled: [String: Bool] = [:]
        for p in FocusPlatform.allCases {
            priorEnabled[p.enabledKey] = defaults?.bool(forKey: p.enabledKey) ?? true
        }

        // Apply: enable selected platforms and tighten their domain thresholds.
        var thresholds = priorThresholds
        for p in targets {
            defaults?.set(true, forKey: p.enabledKey)
            for domain in p.domains { thresholds[domain] = strictness.thresholdBytes }
        }
        saveThresholds(thresholds)

        let session = ActiveFocusSession(
            id: UUID(),
            startedAt: Date(),
            plannedDuration: duration,
            strictness: strictness,
            platforms: targets,
            label: label,
            baselineInterrupted: currentInterruptedCount(),
            priorThresholds: priorThresholds,
            priorEnabled: priorEnabled,
            priorVPNConnected: vpnConnected
        )
        active = session
        liveDistractions = 0
        persistActive()
    }

    /// Ends the running session, restores prior filter config, writes a history
    /// record, and returns it. The caller handles stopping the VPN if needed.
    @discardableResult
    func end(completedFullDuration: Bool) -> FocusSessionRecord? {
        guard let session = active else { return nil }

        refreshLiveDistractions()
        let record = FocusSessionRecord(
            id: session.id,
            startedAt: session.startedAt,
            endedAt: Date(),
            strictness: session.strictness,
            platforms: session.platforms,
            label: session.label,
            distractionsInterrupted: liveDistractions,
            completedFullDuration: completedFullDuration
        )

        // Restore the user's previous filter configuration.
        saveThresholds(session.priorThresholds)
        for (key, value) in session.priorEnabled {
            defaults?.set(value, forKey: key)
        }

        records.append(record)
        lastCompleted = record
        active = nil
        liveDistractions = 0
        persistRecords()
        clearPersistedActive()
        return record
    }

    /// Whether a timed session has reached its planned end.
    var hasReachedPlannedEnd: Bool {
        guard let endsAt = active?.endsAt else { return false }
        return Date() >= endsAt
    }

    // MARK: Live polling

    /// Refreshes the live interrupted count from the tunnel's stats file.
    func refreshLiveDistractions() {
        guard let session = active else { return }
        let current = currentInterruptedCount()
        // Guard against the tunnel's counter resetting (e.g. it restarted).
        liveDistractions = current >= session.baselineInterrupted
            ? current - session.baselineInterrupted
            : current
    }

    /// Reads the tunnel's cumulative blocked-connection count, or 0 if no stats
    /// are available yet.
    private func currentInterruptedCount() -> Int {
        guard let url = statsFileURL,
              let data = try? Data(contentsOf: url),
              let traffic = try? statsDecoder.decode(TrafficData.self, from: data),
              let stats = traffic.snapshots.last?.stats else {
            return 0
        }
        return stats.tcpBlocked
    }

    // MARK: Persistence

    private func load() {
        if let data = defaults?.data(forKey: recordsKey),
           let decoded = try? decoder.decode([FocusSessionRecord].self, from: data) {
            records = decoded
            lastCompleted = decoded.last
        }
        if let data = defaults?.data(forKey: activeKey),
           let decoded = try? decoder.decode(ActiveFocusSession.self, from: data) {
            active = decoded
        }
    }

    private func persistRecords() {
        // Keep history bounded.
        if records.count > 500 { records.removeFirst(records.count - 500) }
        if let data = try? encoder.encode(records) {
            defaults?.set(data, forKey: recordsKey)
        }
    }

    private func persistActive() {
        guard let active, let data = try? encoder.encode(active) else { return }
        defaults?.set(data, forKey: activeKey)
    }

    private func clearPersistedActive() {
        defaults?.removeObject(forKey: activeKey)
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
}
