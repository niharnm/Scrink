import SwiftUI

// MARK: - Tab shell

/// The post-onboarding home: a four-tab control panel (Today / Control / Apps /
/// Progress) in the Signal identity. Rendered inside the app's NavigationStack,
/// so cross-screen pushes (Settings, focus session) layer over the whole shell.
struct MainTabView: View {
    @State private var tab = 0

    var onSettings: (() -> Void)? = nil
    var onStartSession: (() -> Void)? = nil
    var onTrafficDashboard: (() -> Void)? = nil

    var body: some View {
        TabView(selection: $tab) {
            TodayDashboard(
                onSettings: onSettings,
                onStartSession: onStartSession,
                onTrafficDashboard: onTrafficDashboard
            )
            .tabItem { Label("Today", systemImage: "circle.circle") }
            .tag(0)

            ControlScreen(onStart: onStartSession)
                .tabItem { Label("Control", systemImage: "dial.medium") }
                .tag(1)

            AppsScreen()
                .tabItem { Label("Apps", systemImage: "square.grid.2x2") }
                .tag(2)

            ProgressScreen()
                .tabItem { Label("Progress", systemImage: "chart.bar") }
                .tag(3)
        }
        .tint(RinklerColors.signalBlue)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
}

// MARK: - Control tab (session builder)

/// "Choose what disappears, keep what matters." Pre-fills from the user's
/// onboarding traps/keeps. Start hands off to the existing focus-session engine.
struct ControlScreen: View {
    @EnvironmentObject private var focusSystem: FocusSystemStore
    var onStart: (() -> Void)? = nil

    @State private var duration = 25

    private let durations = [25, 45, 60, 90]

    private var disappears: [String] {
        focusSystem.traps.isEmpty ? ["Reels", "Shorts", "TikTok FYP"] : focusSystem.traps.map(\.surface)
    }
    private var keeps: [String] {
        focusSystem.keeps.isEmpty ? ["Messages", "Search"] : focusSystem.keeps.map(\.title)
    }

    var body: some View {
        ZStack {
            SignalBackground()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: RinklerSpacing.lg) {
                    Text("Start a Control Session")
                        .font(RinklerFonts.sans(26, .bold))
                        .foregroundStyle(RinklerColors.signalText)

                    labeledGroup("HOW LONG") {
                        HStack(spacing: 10) {
                            ForEach(durations, id: \.self) { mins in
                                Button { duration = mins } label: {
                                    Text("\(mins)m")
                                        .font(RinklerFonts.mono(15, .medium))
                                        .foregroundStyle(duration == mins ? .black : RinklerColors.signalText)
                                        .frame(maxWidth: .infinity).frame(height: 46)
                                        .background(duration == mins ? AnyView(RinklerColors.signalGlow) : AnyView(RinklerColors.signalCard))
                                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(RinklerColors.signalBorder, lineWidth: duration == mins ? 0 : 1))
                                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    labeledGroup("WHAT DISAPPEARS") {
                        flow(disappears, color: RinklerColors.signalWarning)
                    }

                    labeledGroup("WHAT STAYS OPEN") {
                        flow(keeps, color: RinklerColors.signalSuccess)
                    }

                    Button { onStart?() } label: {
                        Text("Start")
                            .font(RinklerFonts.sans(18, .semibold))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity).frame(height: 56)
                            .background(RinklerColors.signalGlow)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, RinklerSpacing.sm)

                    Text("Start hands off to your focus session, which applies these blocks through the local tunnel.")
                        .font(RinklerFonts.sans(12, .regular))
                        .foregroundStyle(RinklerColors.signalTextDim)
                }
                .padding(RinklerSpacing.lg)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func labeledGroup<C: View>(_ title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(RinklerFonts.sans(12, .semibold))
                .foregroundStyle(RinklerColors.signalTextDim)
            content()
        }
    }

    private func flow(_ items: [String], color: Color) -> some View {
        FlowChips(items: items, color: color)
    }
}

/// Simple wrapping chip row.
private struct FlowChips: View {
    let items: [String]
    let color: Color
    private let columns = [GridItem(.adaptive(minimum: 96), spacing: 8)]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(RinklerFonts.sans(13, .medium))
                    .foregroundStyle(RinklerColors.signalText)
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(color.opacity(0.14))
                    .overlay(Capsule().strokeBorder(color.opacity(0.4), lineWidth: 1))
                    .clipShape(Capsule())
            }
        }
    }
}

// MARK: - Apps tab (feature-level allow/block)

/// The core differentiator: classify *parts* of apps, not whole apps. Toggles
/// that map to a real tunnel filter key actually take effect; others are honest
/// previews until per-feature path control ships.
struct AppsScreen: View {
    @AppStorage(RinklerConstants.blockInstagramShortVideoEnabledKey,
                store: UserDefaults(suiteName: RinklerConstants.appGroupID))
    private var blockInstagram = true

    @AppStorage(RinklerConstants.blockTikTokShortVideoEnabledKey,
                store: UserDefaults(suiteName: RinklerConstants.appGroupID))
    private var blockTikTok = true

    var body: some View {
        ZStack {
            SignalBackground()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: RinklerSpacing.lg) {
                    Text("Apps")
                        .font(RinklerFonts.sans(26, .bold))
                        .foregroundStyle(RinklerColors.signalText)
                    Text("Keep the useful parts. Kill the infinite scroll.")
                        .font(RinklerFonts.sans(14, .regular))
                        .foregroundStyle(RinklerColors.signalTextDim)

                    appCard("Instagram",
                            allowed: ["DMs", "Camera", "Posting", "Search"],
                            blockedFeature: "Reels & Explore video",
                            extraBlocked: ["Explore", "Suggested posts"],
                            isOn: $blockInstagram)

                    appCard("TikTok",
                            allowed: ["Messages", "Profile", "Following"],
                            blockedFeature: "For You feed",
                            extraBlocked: [],
                            isOn: $blockTikTok)

                    // YouTube shares hosts between Shorts and normal playback at the
                    // tunnel layer, so it is shown but not yet a live toggle.
                    appCardStatic("YouTube",
                                  allowed: ["Search", "Subscriptions", "Playlists"],
                                  blocked: ["Shorts", "Home feed", "Recommended"])

                    Text("Blocks act on heavy short-video streams at the network layer. Some feeds share hosts with useful features, so a few controls are previews until per-feature path control ships.")
                        .font(RinklerFonts.sans(12, .regular))
                        .foregroundStyle(RinklerColors.signalTextDim)
                        .padding(.top, RinklerSpacing.sm)
                }
                .padding(RinklerSpacing.lg)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func appCard(_ name: String, allowed: [String], blockedFeature: String,
                         extraBlocked: [String], isOn: Binding<Bool>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(name)
                    .font(RinklerFonts.sans(19, .semibold))
                    .foregroundStyle(RinklerColors.signalText)
                Spacer()
                Toggle("", isOn: isOn).labelsHidden().tint(RinklerColors.signalBlue)
            }
            chipRow("Allowed", allowed, color: RinklerColors.signalSuccess)
            chipRow("Blocked", [blockedFeature] + extraBlocked, color: RinklerColors.signalWarning)
        }
        .padding(RinklerSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RinklerColors.signalCard)
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(RinklerColors.signalBorder, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func appCardStatic(_ name: String, allowed: [String], blocked: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(name)
                    .font(RinklerFonts.sans(19, .semibold))
                    .foregroundStyle(RinklerColors.signalText)
                Spacer()
                Text("Preview")
                    .font(RinklerFonts.sans(11, .medium))
                    .foregroundStyle(RinklerColors.signalTextDim)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(RinklerColors.signalCardRaised)
                    .clipShape(Capsule())
            }
            chipRow("Allowed", allowed, color: RinklerColors.signalSuccess)
            chipRow("Blocked", blocked, color: RinklerColors.signalWarning)
        }
        .padding(RinklerSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RinklerColors.signalCard)
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(RinklerColors.signalBorder, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func chipRow(_ label: String, _ items: [String], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(RinklerFonts.sans(11, .semibold))
                .foregroundStyle(color.opacity(0.9))
            FlowChipsPublic(items: items, color: color)
        }
    }
}

/// Public chip flow reused by the Apps tab.
struct FlowChipsPublic: View {
    let items: [String]
    let color: Color
    private let columns = [GridItem(.adaptive(minimum: 90), spacing: 8)]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(RinklerFonts.sans(12, .medium))
                    .foregroundStyle(RinklerColors.signalText)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(color.opacity(0.12))
                    .overlay(Capsule().strokeBorder(color.opacity(0.35), lineWidth: 1))
                    .clipShape(Capsule())
            }
        }
    }
}

// MARK: - Rule editor

/// Edit a generated preset: name, on/off, time window, difficulty, and which
/// surfaces it blocks / keeps. Saving re-emits the tunnel schedule.
struct RuleEditorView: View {
    @EnvironmentObject private var focusSystem: FocusSystemStore
    @Environment(\.dismiss) private var dismiss
    @State private var draft: FocusRule

    init(rule: FocusRule) { _draft = State(initialValue: rule) }

    private let blockedCatalog = ["Reels", "Shorts", "TikTok FYP", "Explore", "Spotlight", "Reddit feed", "X feed"]
    private let allowedCatalog = ["DMs", "Messages", "Search", "YouTube Search", "School apps", "Music", "Maps", "Calendar", "Family contacts", "Phone", "Alarm"]
    private let cols = [GridItem(.adaptive(minimum: 96), spacing: 8)]

    var body: some View {
        NavigationStack {
            ZStack {
                SignalBackground()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: RinklerSpacing.lg) {
                        group("NAME") {
                            TextField("Rule name", text: $draft.name)
                                .font(RinklerFonts.sans(17, .medium))
                                .foregroundStyle(RinklerColors.signalText)
                                .padding(12)
                                .background(RinklerColors.signalCard)
                                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(RinklerColors.signalBorder, lineWidth: 1))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }

                        Toggle(isOn: $draft.enabled) {
                            Text("Rule enabled")
                                .font(RinklerFonts.sans(15, .medium))
                                .foregroundStyle(RinklerColors.signalText)
                        }
                        .tint(RinklerColors.signalBlue)

                        group("WINDOW") {
                            HStack {
                                DatePicker("Starts", selection: startBinding, displayedComponents: .hourAndMinute)
                                DatePicker("Ends", selection: endBinding, displayedComponents: .hourAndMinute)
                            }
                            .font(RinklerFonts.sans(14, .medium))
                            .foregroundStyle(RinklerColors.signalTextDim)
                            .tint(RinklerColors.signalBlue)
                        }

                        group("STRICTNESS") {
                            Picker("Strictness", selection: difficultyBinding) {
                                ForEach(Difficulty.allCases) { Text($0.title).tag($0) }
                            }
                            .pickerStyle(.segmented)
                        }

                        group("BLOCKS") { chips(blockedCatalog, list: \.blocked, color: RinklerColors.signalWarning) }
                        group("KEEPS OPEN") { chips(allowedCatalog, list: \.allowed, color: RinklerColors.signalSuccess) }

                        Button(role: .destructive) {
                            focusSystem.deleteRule(draft.id)
                            dismiss()
                        } label: {
                            Text("Delete rule")
                                .font(RinklerFonts.sans(15, .medium))
                                .foregroundStyle(RinklerColors.signalWarning)
                                .frame(maxWidth: .infinity).frame(height: 48)
                                .background(RinklerColors.signalCard)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(RinklerSpacing.lg)
                }
            }
            .navigationTitle("Edit rule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { focusSystem.updateRule(draft); dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    private func group<C: View>(_ title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(RinklerFonts.sans(12, .semibold))
                .foregroundStyle(RinklerColors.signalTextDim)
            content()
        }
    }

    private func chips(_ catalog: [String], list: WritableKeyPath<FocusRule, [String]>, color: Color) -> some View {
        LazyVGrid(columns: cols, alignment: .leading, spacing: 8) {
            ForEach(catalog, id: \.self) { item in
                let on = draft[keyPath: list].contains(item)
                Button {
                    if on { draft[keyPath: list].removeAll { $0 == item } }
                    else { draft[keyPath: list].append(item) }
                } label: {
                    Text(item)
                        .font(RinklerFonts.sans(12, .medium))
                        .foregroundStyle(on ? RinklerColors.signalText : RinklerColors.signalTextDim)
                        .padding(.horizontal, 10).padding(.vertical, 7)
                        .background(on ? color.opacity(0.16) : RinklerColors.signalCard)
                        .overlay(Capsule().strokeBorder(on ? color.opacity(0.5) : RinklerColors.signalBorder, lineWidth: 1))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var startBinding: Binding<Date> {
        Binding(get: { Self.date(from: draft.startMinute) }, set: { draft.startMinute = Self.minute(from: $0) })
    }
    private var endBinding: Binding<Date> {
        Binding(get: { Self.date(from: draft.endMinute) }, set: { draft.endMinute = Self.minute(from: $0) })
    }
    private var difficultyBinding: Binding<Difficulty> {
        Binding(get: { draft.difficulty }, set: { draft.difficultyRaw = $0.rawValue })
    }

    private static func date(from minute: Int) -> Date {
        Calendar.current.date(bySettingHour: minute / 60, minute: minute % 60, second: 0, of: Date()) ?? Date()
    }
    private static func minute(from date: Date) -> Int {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }
}

// MARK: - Progress tab (scroll report)

/// Scroll-specific report. Reads the tunnel's blocked counter from the shared
/// stats file when available; otherwise invites the user to start a session.
struct ProgressScreen: View {
    @EnvironmentObject private var focusSystem: FocusSystemStore
    @EnvironmentObject private var sessions: FocusSessionStore
    @State private var noiseBlocked = 0

    var body: some View {
        ZStack {
            SignalBackground()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: RinklerSpacing.lg) {
                    Text("Scroll Report")
                        .font(RinklerFonts.sans(26, .bold))
                        .foregroundStyle(RinklerColors.signalText)

                    HStack(spacing: 12) {
                        statCard("\(noiseBlocked)", "Noise blocked")
                        statCard("\(focusSystem.rules.count)", "Active rules")
                        statCard("\(focusSystem.signalScore)", "Signal score")
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("THIS WEEK")
                            .font(RinklerFonts.sans(12, .semibold))
                            .foregroundStyle(RinklerColors.signalTextDim)
                        Text(noiseBlocked > 0
                             ? "You've cut \(noiseBlocked) short-video pulls so far. Keep your windows armed and the number climbs."
                             : "Start a Control Session to begin your scroll report. Once the tunnel is filtering, blocked pulls and time saved show up here.")
                            .font(RinklerFonts.sans(14, .regular))
                            .foregroundStyle(RinklerColors.signalTextDim)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(RinklerSpacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RinklerColors.signalCard)
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(RinklerColors.signalBorder, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                    ringsSection
                }
                .padding(RinklerSpacing.lg)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear(perform: loadStats)
    }

    // MARK: Signal Rings (rewards)

    private struct RingLevel {
        let title: String
        let requirement: String
    }

    private let levels: [RingLevel] = [
        RingLevel(title: "First Signal", requirement: "Bank your first clean minutes"),
        RingLevel(title: "Double Ring", requirement: "Block 10 scroll pulls"),
        RingLevel(title: "Pulse", requirement: "Hold a 3-day streak"),
        RingLevel(title: "Orbit", requirement: "Save 5 hours in a week"),
        RingLevel(title: "Halo", requirement: "Finish a Locked session"),
    ]

    /// Real fraction (0...1) toward each ring, so locked rings show how close the
    /// user is rather than a flat lock. A ring is unlocked once its fraction hits 1.
    private var fractions: [Double] {
        let weekMin = weeklyFocusMinutes
        let lockedDone = sessions.records.contains { $0.strictness == .deep && $0.completedFullDuration }
        return [
            (weekMin >= 1 || noiseBlocked > 0) ? 1 : 0,
            min(Double(noiseBlocked) / 10, 1),
            min(Double(sessions.streak) / 3, 1),
            min(Double(weekMin) / 300, 1),
            lockedDone ? 1 : 0,
        ]
    }

    private var weeklyFocusMinutes: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let seconds = sessions.records.filter { $0.startedAt >= weekAgo }.reduce(0.0) { $0 + $1.durationSeconds }
        return Int(seconds / 60)
    }

    private var ringsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SIGNAL RINGS")
                .font(RinklerFonts.sans(12, .semibold))
                .foregroundStyle(RinklerColors.signalTextDim)

            ForEach(levels.indices, id: \.self) { i in
                let fraction = fractions[i]
                let isOn = fraction >= 1
                HStack(spacing: RinklerSpacing.md) {
                    SignalRing(progress: isOn ? 1 : max(fraction, 0.06), lineWidth: 4) {
                        Image(systemName: isOn ? "checkmark" : "lock.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(isOn ? RinklerColors.signalSuccess : RinklerColors.signalTextDim)
                    }
                    .frame(width: 38, height: 38)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(levels[i].title)
                            .font(RinklerFonts.sans(15, .semibold))
                            .foregroundStyle(isOn ? RinklerColors.signalText : RinklerColors.signalTextDim)
                        Text(levels[i].requirement)
                            .font(RinklerFonts.sans(12, .regular))
                            .foregroundStyle(RinklerColors.signalTextDim)
                    }
                    Spacer()
                    if !isOn && fraction > 0 {
                        Text("\(Int(fraction * 100))%")
                            .font(RinklerFonts.mono(12, .medium))
                            .foregroundStyle(RinklerColors.signalTextDim)
                    }
                }
                .padding(RinklerSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RinklerColors.signalCard)
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(isOn ? RinklerColors.signalBlue.opacity(0.4) : RinklerColors.signalBorder, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }

    private func statCard(_ value: String, _ label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(RinklerFonts.mono(24, .medium))
                .foregroundStyle(RinklerColors.signalText)
            Text(label)
                .font(RinklerFonts.sans(11, .medium))
                .foregroundStyle(RinklerColors.signalTextDim)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(.vertical, RinklerSpacing.md)
        .background(RinklerColors.signalCard)
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(RinklerColors.signalBorder, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    /// Reads the tunnel's cumulative blocked count from the shared stats file.
    private func loadStats() {
        guard let url = FileManager.default
                .containerURL(forSecurityApplicationGroupIdentifier: RinklerConstants.appGroupID)?
                .appendingPathComponent(RinklerConstants.statsFileName),
              let data = try? Data(contentsOf: url) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let traffic = try? decoder.decode(TrafficData.self, from: data),
           let stats = traffic.snapshots.last?.stats {
            noiseBlocked = stats.tcpBlocked
        }
    }
}
