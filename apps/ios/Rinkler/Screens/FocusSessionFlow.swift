import SwiftUI

// MARK: - Shared building blocks

/// Frosted card used across the redesigned screens.
private struct RinklerCard<Content: View>: View {
    var padding: CGFloat = RinklerSpacing.lg
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RinklerColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(RinklerColors.hairline, lineWidth: 1)
            )
    }
}

/// Primary call-to-action with the aurora accent.
struct AuroraButton: View {
    let title: String
    var enabled: Bool = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(RinklerFonts.pupok(size: 22))
                .foregroundStyle(.black.opacity(0.85))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(RinklerColors.aurora)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .opacity(enabled ? 1 : 0.4)
        }
        .disabled(!enabled)
    }
}

/// Quiet secondary / ghost button.
struct GhostButton: View {
    let title: String
    var tint: Color = .white
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(RinklerFonts.coolvetica(size: 17))
                .foregroundStyle(tint)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(RinklerColors.surfaceRaised)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}

/// Selectable pill used for platforms and durations.
private struct SelectPill: View {
    let title: String
    let selected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(RinklerFonts.coolvetica(size: 15))
                .foregroundStyle(selected ? .black.opacity(0.85) : .white)
                .padding(.horizontal, 16)
                .frame(height: 40)
                .background {
                    if selected {
                        RinklerColors.aurora
                    } else {
                        RinklerColors.surfaceRaised
                    }
                }
                .clipShape(Capsule())
                .overlay(
                    Capsule().strokeBorder(RinklerColors.hairline, lineWidth: selected ? 0 : 1)
                )
        }
    }
}

// MARK: - 1. Setup

struct FocusSetupScreen: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var vpnManager: VPNManager
    @EnvironmentObject private var sessions: FocusSessionStore

    var onBegin: () -> Void

    @State private var label = ""
    @State private var platforms: Set<FocusPlatform> = Set(FocusPlatform.allCases)
    @State private var strictness: FocusStrictness = .focused
    @State private var durationMinutes: Int = 45  // 0 == open-ended

    private let durationOptions: [Int] = [25, 45, 60, 90, 0]

    /// Deep focus can't be ended early, so it must have a fixed length —
    /// "Open" is hidden for it.
    private var visibleDurationOptions: [Int] {
        strictness == .deep ? durationOptions.filter { $0 != 0 } : durationOptions
    }

    var body: some View {
        ZStack {
            SkyBackgroundView(clarity: 0.28)

            ScrollView {
                VStack(alignment: .leading, spacing: RinklerSpacing.lg) {
                    Text("New focus session")
                        .font(RinklerFonts.coolvetica(size: 28))
                        .foregroundStyle(.white)
                        .padding(.top, RinklerSpacing.sm)

                    intentionCard
                    platformCard
                    strictnessCard
                    durationCard

                    AuroraButton(title: "BEGIN FOCUS", enabled: !platforms.isEmpty) {
                        begin()
                    }
                    .padding(.top, RinklerSpacing.xs)

                    Text("Rinkler interrupts the heavy short-video streams from the apps you pick. It filters at the network layer on this device — it doesn't read your messages or page contents.")
                        .font(RinklerFonts.caption)
                        .foregroundStyle(RinklerColors.white40)
                        .padding(.top, RinklerSpacing.xs)
                }
                .padding(.horizontal, RinklerSpacing.lg)
                .padding(.bottom, RinklerSpacing.xxl)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: { BackArrowView() }
            }
        }
        .onChange(of: strictness) { _, newValue in
            if newValue == .deep && durationMinutes == 0 { durationMinutes = 45 }
        }
    }

    private var intentionCard: some View {
        RinklerCard {
            VStack(alignment: .leading, spacing: RinklerSpacing.sm) {
                Text("WHAT ARE YOU PROTECTING?")
                    .font(RinklerFonts.caption)
                    .foregroundStyle(RinklerColors.white40)
                TextField("", text: $label, prompt: Text("e.g. finish the essay").foregroundColor(RinklerColors.white40))
                    .font(RinklerFonts.coolvetica(size: 20))
                    .foregroundStyle(.white)
                    .tint(RinklerColors.auroraCyan)
                    .textInputAutocapitalization(.never)
            }
        }
    }

    private var platformCard: some View {
        RinklerCard {
            VStack(alignment: .leading, spacing: RinklerSpacing.md) {
                Text("WHAT TO INTERRUPT")
                    .font(RinklerFonts.caption)
                    .foregroundStyle(RinklerColors.white40)
                HStack(spacing: RinklerSpacing.sm) {
                    ForEach(FocusPlatform.allCases) { platform in
                        platformToggle(platform)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private func platformToggle(_ platform: FocusPlatform) -> some View {
        let selected = platforms.contains(platform)
        return Button {
            if selected { platforms.remove(platform) } else { platforms.insert(platform) }
        } label: {
            HStack(spacing: RinklerSpacing.sm) {
                SocialMediaIcon(platform: platform.iconKey, size: 26)
                    .frame(width: 38, height: 38)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                Text(platform.title)
                    .font(RinklerFonts.coolvetica(size: 16))
                    .foregroundStyle(.white)
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected ? RinklerColors.auroraCyan : RinklerColors.white30)
            }
            .padding(.horizontal, RinklerSpacing.md)
            .padding(.vertical, RinklerSpacing.sm)
            .background(RinklerColors.surfaceRaised)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(selected ? RinklerColors.auroraCyan.opacity(0.6) : RinklerColors.hairline, lineWidth: 1)
            )
        }
    }

    private var strictnessCard: some View {
        RinklerCard {
            VStack(alignment: .leading, spacing: RinklerSpacing.md) {
                Text("HOW STRICT")
                    .font(RinklerFonts.caption)
                    .foregroundStyle(RinklerColors.white40)

                ForEach(FocusStrictness.allCases) { level in
                    strictnessRow(level)
                }

                if strictness == .deep {
                    Text("Deep can't be ended early inside Rinkler. You can still turn the VPN off in iOS Settings — Rinkler won't override the system.")
                        .font(RinklerFonts.caption)
                        .foregroundStyle(RinklerColors.dawnGlow.opacity(0.9))
                        .padding(.top, 2)
                }
            }
        }
    }

    private func strictnessRow(_ level: FocusStrictness) -> some View {
        let selected = strictness == level
        return Button {
            strictness = level
        } label: {
            HStack(alignment: .top, spacing: RinklerSpacing.md) {
                Image(systemName: level.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(selected ? RinklerColors.auroraCyan : .white)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(level.title)
                        .font(RinklerFonts.coolvetica(size: 18))
                        .foregroundStyle(.white)
                    Text(level.tagline)
                        .font(RinklerFonts.caption)
                        .foregroundStyle(RinklerColors.white60)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(selected ? RinklerColors.auroraCyan : RinklerColors.white30)
            }
            .padding(.vertical, RinklerSpacing.xs)
        }
    }

    private var durationCard: some View {
        RinklerCard {
            VStack(alignment: .leading, spacing: RinklerSpacing.md) {
                Text("FOR HOW LONG")
                    .font(RinklerFonts.caption)
                    .foregroundStyle(RinklerColors.white40)
                HStack(spacing: RinklerSpacing.sm) {
                    ForEach(visibleDurationOptions, id: \.self) { mins in
                        SelectPill(
                            title: mins == 0 ? "Open" : "\(mins)m",
                            selected: durationMinutes == mins
                        ) {
                            durationMinutes = mins
                        }
                    }
                }
                if strictness == .deep {
                    Text("Deep needs a set length — it can't be ended early.")
                        .font(RinklerFonts.caption)
                        .foregroundStyle(RinklerColors.white40)
                }
            }
        }
    }

    private func begin() {
        let wasConnected = vpnManager.vpnStatus == .connected
        sessions.start(
            platforms: Array(platforms),
            strictness: strictness,
            duration: TimeInterval(durationMinutes * 60),
            label: label.trimmingCharacters(in: .whitespacesAndNewlines),
            vpnConnected: wasConnected
        )
        if !wasConnected {
            vpnManager.startVPN()
        }
        onBegin()
    }
}

// MARK: - 2. Active session

struct ActiveSessionScreen: View {
    @EnvironmentObject private var vpnManager: VPNManager
    @EnvironmentObject private var sessions: FocusSessionStore

    var onEnd: () -> Void

    @State private var now = Date()
    @State private var showEndConfirm = false
    @State private var ending = false

    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            SkyBackgroundView(clarity: 0.85)

            if let session = sessions.active {
                VStack(spacing: RinklerSpacing.xl) {
                    Spacer()

                    VStack(spacing: RinklerSpacing.sm) {
                        Text(session.label.isEmpty ? "In focus" : session.label)
                            .font(RinklerFonts.coolvetica(size: 20))
                            .foregroundStyle(RinklerColors.white60)
                            .multilineTextAlignment(.center)

                        Text(timeDisplay(for: session))
                            .font(RinklerFonts.mono(76, .medium))
                            .foregroundStyle(.white)
                            .monospacedDigit()
                            .contentTransition(.numericText())

                        Text(session.plannedDuration > 0 ? "remaining" : "elapsed")
                            .font(RinklerFonts.caption)
                            .foregroundStyle(RinklerColors.white40)
                    }

                    distractionsView

                    platformStrip(session)

                    Spacer()

                    endControl(session)
                        .padding(.horizontal, RinklerSpacing.lg)
                        .padding(.bottom, RinklerSpacing.xl)
                }
                .frame(maxWidth: .infinity)
            } else {
                ProgressView().tint(.white)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onReceive(tick) { _ in
            now = Date()
            sessions.refreshLiveDistractions()
            if sessions.hasReachedPlannedEnd {
                complete(fullDuration: true)
            }
        }
        .alert("End this session?", isPresented: $showEndConfirm) {
            Button("Keep focusing", role: .cancel) { }
            Button("End now", role: .destructive) { complete(fullDuration: false) }
        } message: {
            Text("You're protecting your attention right now. Sure you want to stop early?")
        }
    }

    private var distractionsView: some View {
        VStack(spacing: 4) {
            Text("\(sessions.liveDistractions)")
                .font(RinklerFonts.mono(34, .medium))
                .foregroundStyle(RinklerColors.auroraCyan)
                .monospacedDigit()
                .contentTransition(.numericText())
            Text(sessions.liveDistractions == 1 ? "distraction interrupted" : "distractions interrupted")
                .font(RinklerFonts.caption)
                .foregroundStyle(RinklerColors.white60)
        }
    }

    private func platformStrip(_ session: ActiveFocusSession) -> some View {
        HStack(spacing: RinklerSpacing.sm) {
            ForEach(session.platforms) { platform in
                SocialMediaIcon(platform: platform.iconKey, size: 22)
                    .frame(width: 34, height: 34)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 9))
            }
            Text(session.strictness.title.uppercased())
                .font(RinklerFonts.caption)
                .foregroundStyle(RinklerColors.white40)
                .padding(.leading, 4)
        }
    }

    @ViewBuilder
    private func endControl(_ session: ActiveFocusSession) -> some View {
        if session.strictness.allowsEarlyStop {
            GhostButton(title: "End session", tint: RinklerColors.dawnGlow) {
                showEndConfirm = true
            }
        } else {
            VStack(spacing: RinklerSpacing.xs) {
                HStack(spacing: RinklerSpacing.sm) {
                    Image(systemName: "lock.fill")
                    Text(lockLabel(session))
                }
                .font(RinklerFonts.coolvetica(size: 16))
                .foregroundStyle(RinklerColors.white40)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(RinklerColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                Text("Deep focus holds until the timer ends.")
                    .font(RinklerFonts.caption)
                    .foregroundStyle(RinklerColors.white30)
            }
        }
    }

    private func lockLabel(_ session: ActiveFocusSession) -> String {
        guard let endsAt = session.endsAt else { return "Locked" }
        return "Locked until \(endsAt.formatted(date: .omitted, time: .shortened))"
    }

    private func timeDisplay(for session: ActiveFocusSession) -> String {
        let interval: TimeInterval
        if let endsAt = session.endsAt {
            interval = max(0, endsAt.timeIntervalSince(now))
        } else {
            interval = max(0, now.timeIntervalSince(session.startedAt))
        }
        let total = Int(interval)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }

    private func complete(fullDuration: Bool) {
        guard !ending, sessions.active != nil else { return }
        ending = true
        let priorConnected = sessions.active?.priorVPNConnected ?? true
        sessions.end(completedFullDuration: fullDuration)
        // Restore VPN to its pre-session state.
        if !priorConnected && vpnManager.vpnStatus == .connected {
            vpnManager.toggleVPN()
        }
        onEnd()
    }
}

// MARK: - 3. Recap

struct SessionRecapScreen: View {
    @EnvironmentObject private var sessions: FocusSessionStore
    var onDone: () -> Void

    var body: some View {
        ZStack {
            SkyBackgroundView(clarity: 0.95)

            if let record = sessions.lastCompleted {
                ScrollView {
                    VStack(spacing: RinklerSpacing.lg) {
                        Spacer().frame(height: RinklerSpacing.xxl)

                        Text(headline(record))
                            .font(RinklerFonts.coolvetica(size: 30))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, RinklerSpacing.lg)

                        VStack(spacing: 2) {
                            Text(focusedTime(record))
                                .font(RinklerFonts.hero)
                                .foregroundStyle(.white)
                            Text("of focus protected")
                                .font(RinklerFonts.heroUnit)
                                .foregroundStyle(RinklerColors.white60)
                        }
                        .padding(.vertical, RinklerSpacing.md)

                        HStack(spacing: RinklerSpacing.md) {
                            recapStat(value: "\(record.distractionsInterrupted)", label: "interrupted")
                            recapStat(value: "\(sessions.streak)", label: sessions.streak == 1 ? "day streak" : "day streak")
                        }
                        .padding(.horizontal, RinklerSpacing.lg)

                        Text(closingLine(record))
                            .font(RinklerFonts.coolvetica(size: 16))
                            .foregroundStyle(RinklerColors.white60)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, RinklerSpacing.xl)

                        Spacer().frame(height: RinklerSpacing.lg)

                        AuroraButton(title: "DONE") { onDone() }
                            .padding(.horizontal, RinklerSpacing.lg)
                            .padding(.bottom, RinklerSpacing.xl)
                    }
                    .frame(maxWidth: .infinity)
                }
            } else {
                VStack {
                    Spacer()
                    AuroraButton(title: "DONE") { onDone() }
                        .padding(RinklerSpacing.lg)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    private func recapStat(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(RinklerFonts.statNumber)
                .foregroundStyle(RinklerColors.auroraCyan)
            Text(label)
                .font(RinklerFonts.caption)
                .foregroundStyle(RinklerColors.white60)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, RinklerSpacing.md)
        .background(RinklerColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(RinklerColors.hairline, lineWidth: 1)
        )
    }

    private func headline(_ record: FocusSessionRecord) -> String {
        record.completedFullDuration ? "You finished strong." : "Every minute counted."
    }

    private func focusedTime(_ record: FocusSessionRecord) -> String {
        let total = Int(record.durationSeconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        if h > 0 { return m > 0 ? "\(h)h \(m)m" : "\(h)h" }
        if m > 0 { return "\(m)m" }
        return "\(total)s"
    }

    private func closingLine(_ record: FocusSessionRecord) -> String {
        if record.label.isEmpty {
            return "That time was yours. Come back whenever you want to protect more."
        }
        return "Time you gave to “\(record.label).” Come back whenever you want to protect more."
    }
}
