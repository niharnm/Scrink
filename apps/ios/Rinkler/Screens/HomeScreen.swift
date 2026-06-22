import SwiftUI

struct HomeScreen: View {
    @Environment(AuthStore.self) private var authStore
    @EnvironmentObject private var vpnManager: VPNManager
    @EnvironmentObject private var sessions: FocusSessionStore
    @EnvironmentObject private var commitment: CommitmentStore

    @State private var showUnlock = false

    var onSignIn: (() -> Void)? = nil
    var onSettings: (() -> Void)? = nil
    var onTrafficDashboard: (() -> Void)? = nil
    var onStartSession: (() -> Void)? = nil
    var onResumeSession: (() -> Void)? = nil
    var onJourney: (() -> Void)? = nil

    var body: some View {
        ZStack {
            SkyBackgroundView(clarity: sessions.storyClarity)

            ScrollView {
                VStack(alignment: .leading, spacing: RinklerSpacing.lg) {
                    header
                    heroCard
                    if sessions.isRunning {
                        resumeCard
                    } else {
                        AuroraButton(title: "START FOCUS SESSION") { onStartSession?() }
                    }
                    journeyCard
                    protectionCard
                    accountRow
                }
                .padding(.horizontal, RinklerSpacing.lg)
                .padding(.top, RinklerSpacing.lg)
                .padding(.bottom, RinklerSpacing.xxl)
            }
        }
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showUnlock) {
            CommitmentUnlockSheet(
                cooldownSeconds: commitment.cooldownSeconds,
                onConfirm: {
                    vpnManager.toggleVPN()
                    commitment.recordDisable()
                    showUnlock = false
                },
                onCancel: { showUnlock = false }
            )
        }
    }

    /// Start is always one tap. Stopping while Commitment Mode is on routes
    /// through the friction sheet instead of toggling immediately.
    private func handleProtectionTap() {
        let isOn = vpnManager.vpnStatus == .connected || vpnManager.vpnStatus == .connecting
        if isOn && commitment.isEnabled {
            showUnlock = true
        } else {
            vpnManager.toggleVPN()
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .center) {
            Text("RINKLER")
                .font(RinklerFonts.headerTitle)
                .foregroundStyle(.white)
            Spacer()
            HStack(spacing: RinklerSpacing.sm) {
                iconButton(systemName: "chart.bar.fill", label: "Traffic dashboard", action: onTrafficDashboard)
                iconButton(systemName: "gearshape.fill", label: "Settings", action: onSettings)
            }
        }
    }

    // MARK: Hero — the one number

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: RinklerSpacing.md) {
            Text(greeting.uppercased())
                .font(RinklerFonts.caption)
                .foregroundStyle(RinklerColors.white40)

            VStack(alignment: .leading, spacing: 0) {
                Text(heroValue)
                    .font(RinklerFonts.hero)
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                Text(heroSubtitle)
                    .font(RinklerFonts.heroUnit)
                    .foregroundStyle(RinklerColors.white60)
            }

            HStack(spacing: RinklerSpacing.sm) {
                statChip(value: "\(sessions.todayDistractions)", label: "interrupted")
                statChip(value: "\(sessions.sessionsToday)", label: sessions.sessionsToday == 1 ? "session" : "sessions")
                statChip(value: "\(sessions.streak)", label: "day streak", glow: sessions.streak > 0)
            }
        }
        .padding(RinklerSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RinklerColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(RinklerColors.hairline, lineWidth: 1)
        )
    }

    private func statChip(value: String, label: String, glow: Bool = false) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(RinklerFonts.statNumber)
                .foregroundStyle(glow ? RinklerColors.auroraCyan : .white)
            Text(label)
                .font(RinklerFonts.caption)
                .foregroundStyle(RinklerColors.white60)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, RinklerSpacing.sm)
        .background(RinklerColors.surfaceRaised)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: Active session resume

    private var resumeCard: some View {
        Button { onResumeSession?() } label: {
            HStack(spacing: RinklerSpacing.md) {
                Image(systemName: "circle.hexagongrid.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(RinklerColors.auroraCyan)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Session in progress")
                        .font(RinklerFonts.coolvetica(size: 18))
                        .foregroundStyle(.white)
                    Text("Tap to return to your focus screen")
                        .font(RinklerFonts.caption)
                        .foregroundStyle(RinklerColors.white60)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(RinklerColors.white40)
            }
            .padding(RinklerSpacing.md)
            .background(RinklerColors.aurora.opacity(0.18))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(RinklerColors.auroraCyan.opacity(0.4), lineWidth: 1)
            )
        }
    }

    // MARK: Story Mode — journey entry

    private var journeyCard: some View {
        let progress = sessions.storyProgress
        let current = Story.currentChapter(progress)
        let next = Story.nextChapter(progress)
        return Button { onJourney?() } label: {
            HStack(spacing: RinklerSpacing.md) {
                Image(systemName: "sparkles")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(RinklerColors.auroraCyan)
                    .frame(width: 44, height: 44)
                    .background(RinklerColors.surfaceRaised)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(current?.title ?? "Begin your journey")
                        .font(RinklerFonts.coolvetica(size: 17))
                        .foregroundStyle(.white)
                    Text(next.map { "Next: \($0.goal.requirementText)" } ?? "The sky is clear — final chapter reached.")
                        .font(RinklerFonts.caption)
                        .foregroundStyle(RinklerColors.white60)
                        .lineLimit(1)
                }
                Spacer(minLength: RinklerSpacing.sm)
                Image(systemName: "chevron.right")
                    .foregroundStyle(RinklerColors.white40)
            }
            .padding(RinklerSpacing.md)
            .background(RinklerColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(RinklerColors.hairline, lineWidth: 1)
            )
        }
    }

    // MARK: Protection (compact)

    private var protectionCard: some View {
        HStack(spacing: RinklerSpacing.md) {
            Image(systemName: vpnManager.vpnStatus == .connected ? "shield.lefthalf.filled" : "shield.slash")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(vpnManager.vpnStatus == .connected ? RinklerColors.auroraCyan : RinklerColors.white40)
                .frame(width: 44, height: 44)
                .background(RinklerColors.surfaceRaised)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(protectionTitle)
                    .font(RinklerFonts.coolvetica(size: 17))
                    .foregroundStyle(.white)
                Text(protectionSubtitle)
                    .font(RinklerFonts.caption)
                    .foregroundStyle(RinklerColors.white60)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: RinklerSpacing.sm)

            if !sessions.isRunning {
                Button {
                    handleProtectionTap()
                } label: {
                    Text(vpnManager.vpnStatus == .connected ? "Stop" : "Start")
                        .font(RinklerFonts.coolvetica(size: 15))
                        .foregroundStyle(vpnManager.vpnStatus == .connected ? RinklerColors.dawnGlow : .black.opacity(0.85))
                        .padding(.horizontal, 18)
                        .frame(height: 38)
                        .background {
                            if vpnManager.vpnStatus == .connected {
                                RinklerColors.surfaceRaised
                            } else {
                                RinklerColors.aurora
                            }
                        }
                        .clipShape(Capsule())
                }
                .disabled(vpnManager.isPreparingProfile)
            }
        }
        .padding(RinklerSpacing.md)
        .background(RinklerColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(RinklerColors.hairline, lineWidth: 1)
        )
    }

    // MARK: Account

    private var accountRow: some View {
        Group {
            if authStore.isLoggedIn {
                Button { onTrafficDashboard?() } label: {
                    accountRowLabel(
                        icon: "checkmark.icloud",
                        title: "Synced",
                        subtitle: authStore.userEmail.isEmpty ? "Traffic summaries sync to your dashboard." : authStore.userEmail
                    )
                }
            } else {
                Button { onSignIn?() } label: {
                    accountRowLabel(
                        icon: "icloud.slash",
                        title: "Sync is off",
                        subtitle: "Sign in to sync summaries. Filtering still runs locally."
                    )
                }
            }
        }
    }

    private func accountRowLabel(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: RinklerSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(RinklerColors.white60)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(RinklerFonts.coolvetica(size: 16))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(RinklerFonts.caption)
                    .foregroundStyle(RinklerColors.white60)
                    .lineLimit(1)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(RinklerColors.white30)
        }
        .padding(.vertical, RinklerSpacing.sm)
        .padding(.horizontal, RinklerSpacing.xs)
    }

    private func iconButton(systemName: String, label: String, action: (() -> Void)?) -> some View {
        Button { action?() } label: {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(RinklerColors.surfaceRaised)
                .clipShape(Circle())
        }
        .disabled(action == nil)
        .accessibilityLabel(label)
    }

    // MARK: Copy

    private var greeting: String {
        sessions.todayFocusSeconds > 0 ? "Today" : "Welcome back"
    }

    private var heroValue: String {
        let total = Int(sessions.todayFocusSeconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        if total == 0 { return "0m" }
        if h > 0 { return m > 0 ? "\(h)h \(m)m" : "\(h)h" }
        return "\(m)m"
    }

    private var heroSubtitle: String {
        sessions.todayFocusSeconds > 0 ? "of focus protected today" : "start a session to protect your focus"
    }

    private var protectionTitle: String {
        switch vpnManager.vpnStatus {
        case .connected: return "Protection on"
        case .connecting, .reasserting: return "Starting protection"
        case .disconnecting: return "Stopping protection"
        case .invalid: return "VPN needs setup"
        default: return "Protection off"
        }
    }

    private var protectionSubtitle: String {
        if sessions.isRunning { return "Held by your active focus session." }
        switch vpnManager.vpnStatus {
        case .connected:
            return commitment.isEnabled
                ? "Locked in — a \(commitment.cooldownLabel) pause guards the stop button."
                : "Filtering supported traffic on this device."
        case .connecting, .reasserting: return "Preparing the local VPN tunnel."
        case .invalid: return "Open Settings if iOS needs VPN permission."
        default: return "Turn on to filter outside a focus session."
        }
    }
}

#Preview {
    HomeScreen()
        .environment(AuthStore())
        .environmentObject(VPNManager())
        .environmentObject(FocusSessionStore())
        .environmentObject(CommitmentStore())
}
