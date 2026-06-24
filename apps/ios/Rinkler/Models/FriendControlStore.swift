import Foundation
import Combine

/// Owner side of friend remote control: generate a short-lived code + a window,
/// then poll for the limits a friend sets and apply them locally (and restore the
/// owner's own settings when the window ends or is revoked). "Strict Mode, but a
/// friend holds the key." Requires the owner to be signed in.
@MainActor
final class FriendControlStore: ObservableObject {
    struct Pairing: Codable, Identifiable {
        let id: String
        let code: String
        let window_end: String
        let friend_user_id: String?
        let redeemed_at: String?
        let revoked: Bool
        var windowEnd: Date { FriendControlStore.parse(window_end) ?? .distantPast }
        var redeemed: Bool { friend_user_id != nil && redeemed_at != nil }
    }
    private struct Limit: Codable { let app_id: String; let feature_id: String; let enabled: Bool }

    @Published private(set) var pairing: Pairing?
    @Published private(set) var appliedCount: Int = 0
    @Published var busy = false
    @Published var error: String?

    private let defaults = UserDefaults(suiteName: RinklerConstants.appGroupID)
    private let client = SupabaseAuthClient.shared
    private var ticker: AnyCancellable?

    private let decoder = JSONDecoder()

    var isControlled: Bool {
        guard let p = pairing, p.redeemed, !p.revoked else { return false }
        return p.windowEnd > Date()
    }
    var hasPendingCode: Bool {
        guard let p = pairing, !p.redeemed, !p.revoked else { return false }
        return p.windowEnd > Date()
    }
    var windowRemainingLabel: String {
        guard let end = pairing?.windowEnd else { return "" }
        let s = max(0, Int(end.timeIntervalSinceNow)); let h = s/3600, m = (s%3600)/60
        return h > 0 ? "\(h)h \(m)m left" : "\(m)m left"
    }

    var isSignedIn: Bool { client.loadSession() != nil }

    // MARK: - Actions

    func generateCode(windowHours: Int) async {
        guard let uid = client.loadSession()?.userID else { error = "Sign in first."; return }
        busy = true; defer { busy = false }
        do {
            // Retire any code that's still pending for this owner, so we never
            // leave an outstanding code the UI can't see and we satisfy the
            // one-live-code-per-owner constraint before inserting the new row.
            try await retirePendingCodes(ownerID: uid)

            let code = String(format: "%06d", Int.random(in: 0...999_999))
            var (req, _) = try await client.authenticatedRESTRequest(path: "friend_pairings", method: "POST")
            req.setValue("return=representation", forHTTPHeaderField: "Prefer")
            let now = Date()
            let body: [String: Any] = [
                "owner_user_id": uid,
                "code": code,
                "code_expires_at": Self.iso(now.addingTimeInterval(900)),     // 15 min to redeem
                "window_end": Self.iso(now.addingTimeInterval(Double(windowHours) * 3600)),
            ]
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard (resp as? HTTPURLResponse)?.statusCode == 201 else { throw Self.httpError(data) }
            pairing = try decoder.decode([Pairing].self, from: data).first
            error = nil
            startTicker()
        } catch { self.error = friendly(error) }
    }

    func refresh() async {
        // Restore is decoupled from auth: if signed out with a window still
        // applied, clear it rather than leaving the friend's blocks stuck on.
        guard let uid = client.loadSession()?.userID else { restoreIfNeeded(); return }
        do {
            let (req, _) = try await client.authenticatedRESTRequest(
                path: "friend_pairings", method: "GET",
                queryItems: [
                    .init(name: "owner_user_id", value: "eq.\(uid)"),
                    .init(name: "revoked", value: "eq.false"),
                    .init(name: "order", value: "created_at.desc"),
                    .init(name: "limit", value: "1"),
                ])
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard (resp as? HTTPURLResponse)?.statusCode == 200 else { return }
            pairing = try decoder.decode([Pairing].self, from: data).first

            if isControlled, let pid = pairing?.id {
                await applyLimits(pairingID: pid, ownerID: uid)
                startTicker()
            } else {
                restoreIfNeeded()
            }
        } catch { /* keep last state */ }
    }

    func revoke() async {
        guard let p = pairing else { return }
        busy = true; defer { busy = false }
        do {
            var (req, _) = try await client.authenticatedRESTRequest(
                path: "friend_pairings", method: "PATCH",
                queryItems: [.init(name: "id", value: "eq.\(p.id)")])
            // Stamp revoked_at so the friend has a real record that the window was
            // ended early, not just a silent boolean flip.
            req.httpBody = try JSONSerialization.data(withJSONObject: [
                "revoked": true,
                "revoked_at": Self.iso(Date()),
            ])
            _ = try await URLSession.shared.data(for: req)
            restoreIfNeeded()
            pairing = nil
            ticker?.cancel(); ticker = nil
        } catch { self.error = friendly(error) }
    }

    /// Revoke every still-pending (unredeemed, not-revoked) code for this owner.
    /// Best-effort: a failure here shouldn't block generating a fresh code.
    private func retirePendingCodes(ownerID: String) async throws {
        var (req, _) = try await client.authenticatedRESTRequest(
            path: "friend_pairings", method: "PATCH",
            queryItems: [
                .init(name: "owner_user_id", value: "eq.\(ownerID)"),
                .init(name: "redeemed_at", value: "is.null"),
                .init(name: "revoked", value: "eq.false"),
            ])
        req.httpBody = try JSONSerialization.data(withJSONObject: [
            "revoked": true,
            "revoked_at": Self.iso(Date()),
        ])
        _ = try? await URLSession.shared.data(for: req)
    }

    /// Called on launch + foreground.
    func tick() {
        // Self-heal: if the window has already passed (known locally), drop the
        // friend's blocks even with no network or session.
        if let end = defaults?.object(forKey: RinklerConstants.friendWindowEndKey) as? Double,
           Date().timeIntervalSince1970 >= end {
            restoreIfNeeded()
        }
        if isControlled, ticker == nil { startTicker() }
        Task { await refresh() }
    }

    // MARK: - Apply / restore
    //
    // The friend's feeds live in their OWN App Group key, never the user's
    // selection — blockedHosts is the union of both. So the Apps tab and friend
    // control can't clobber each other, and there's no snapshot to get stale.

    private func applyLimits(pairingID: String, ownerID: String) async {
        do {
            let (req, _) = try await client.authenticatedRESTRequest(
                path: "friend_set_limits", method: "GET",
                queryItems: [
                    .init(name: "owner_user_id", value: "eq.\(ownerID)"),
                    .init(name: "pairing_id", value: "eq.\(pairingID)"),
                    .init(name: "select", value: "app_id,feature_id,enabled"),
                ])
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard (resp as? HTTPURLResponse)?.statusCode == 200 else { return }
            let limits = try decoder.decode([Limit].self, from: data)
            let friendKeys = limits.filter { $0.enabled }.map { "\($0.app_id)/\($0.feature_id)" }
            defaults?.set(friendKeys, forKey: RinklerConstants.friendBlockFeaturesKey)
            if let end = pairing?.windowEnd {
                defaults?.set(end.timeIntervalSince1970, forKey: RinklerConstants.friendWindowEndKey)
            }
            resolveBlockedHosts()
            appliedCount = friendKeys.count
        } catch { /* keep */ }
    }

    private func restoreIfNeeded() {
        guard defaults?.object(forKey: RinklerConstants.friendBlockFeaturesKey) != nil else { return }
        defaults?.removeObject(forKey: RinklerConstants.friendBlockFeaturesKey)
        defaults?.removeObject(forKey: RinklerConstants.friendWindowEndKey)
        resolveBlockedHosts()
        appliedCount = 0
    }

    /// blockedHosts = hosts(owner's feeds ∪ friend's feeds).
    private func resolveBlockedHosts() {
        let user = Set(defaults?.stringArray(forKey: RinklerConstants.blockSelectionFeaturesKey) ?? [])
        let friend = Set(defaults?.stringArray(forKey: RinklerConstants.friendBlockFeaturesKey) ?? [])
        defaults?.set(BlockCatalog.hosts(forEnabled: user.union(friend)), forKey: RinklerConstants.blockedHostsKey)
    }

    // MARK: - Helpers

    private func startTicker() {
        ticker?.cancel()
        // Poll fast while a window is live so a friend's toggle lands within a few
        // seconds (the timer only fires while the app is foregrounded, so this
        // isn't a background battery cost). True instant/background delivery needs
        // a push wake-up — tracked as a follow-up.
        ticker = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                self.objectWillChange.send()
                if let end = self.pairing?.windowEnd, end <= Date() {
                    self.restoreIfNeeded(); self.ticker?.cancel(); self.ticker = nil
                }
                Task { await self.refresh() }
            }
    }

    nonisolated static func iso(_ d: Date) -> String {
        let f = ISO8601DateFormatter(); f.formatOptions = [.withInternetDateTime]
        return f.string(from: d)
    }
    nonisolated static func parse(_ s: String) -> Date? {
        let f = ISO8601DateFormatter(); f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f.date(from: s) { return d }
        let g = ISO8601DateFormatter(); g.formatOptions = [.withInternetDateTime]
        return g.date(from: s)
    }
    private func friendly(_ error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? "Something went wrong. Try again."
    }
    private static func httpError(_ data: Data) -> Error {
        NSError(domain: "FriendControl", code: 1,
                userInfo: [NSLocalizedDescriptionKey: String(data: data, encoding: .utf8) ?? "Request failed"])
    }
}
