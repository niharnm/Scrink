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
                VStack(alignment: .leading, spacing: RinklerSpacing.md) {
                    header
                    heroCard
                    changesCard
                    quickLinks
                    startButton
                    Text("Hit start and the blocks kick in right on your phone. Nothing leaves your device.")
                        .font(RinklerFonts.sans(12, .regular))
                        .foregroundStyle(RinklerColors.signalTextDim)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 2)
                }
                .padding(RinklerSpacing.lg)
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(nil)
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("CONTROL")
                .font(RinklerFonts.sans(13, .semibold))
                .tracking(2)
                .foregroundStyle(RinklerColors.signalTextDim)
            Text("Build a focus session")
                .font(RinklerFonts.sans(25, .bold))
                .foregroundStyle(RinklerColors.signalText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 2)
    }

    // MARK: Hero — duration as the headline number

    private var heroCard: some View {
        VStack(spacing: RinklerSpacing.md) {
            Text("FOCUS FOR")
                .font(RinklerFonts.sans(12, .semibold))
                .tracking(2)
                .foregroundStyle(RinklerColors.signalTextFaint)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(duration)")
                    .font(.system(size: 68, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(RinklerColors.signalText)
                    .contentTransition(.numericText())
                Text("min")
                    .font(RinklerFonts.sans(20, .semibold))
                    .foregroundStyle(RinklerColors.signalTextDim)
            }

            HStack(spacing: 8) {
                ForEach(durations, id: \.self) { mins in
                    Button { withAnimation(.snappy) { duration = mins } } label: {
                        Text("\(mins)m")
                            .font(RinklerFonts.mono(14, .medium))
                            .foregroundStyle(duration == mins ? RinklerColors.signalOnInk : RinklerColors.signalText)
                            .frame(maxWidth: .infinity).frame(height: 42)
                            .background(duration == mins ? AnyView(RinklerColors.signalInk) : AnyView(RinklerColors.signalCardRaised))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, RinklerSpacing.lg)
        .padding(.horizontal, RinklerSpacing.md)
        .frame(maxWidth: .infinity)
        .signalCard(cornerRadius: 24)
    }

    // MARK: What changes — one organized card

    private var changesCard: some View {
        VStack(spacing: 0) {
            changeRow("DISAPPEARS", disappears, color: RinklerColors.signalWarning, icon: "eye.slash.fill")
            Divider().overlay(RinklerColors.signalBorder).padding(.horizontal, RinklerSpacing.md)
            changeRow("STAYS OPEN", keeps, color: RinklerColors.signalSuccess, icon: "checkmark.circle.fill")
        }
        .signalCard(cornerRadius: 20)
    }

    private func changeRow(_ title: String, _ items: [String], color: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(color)
                Text(title)
                    .font(RinklerFonts.sans(12, .semibold))
                    .tracking(1)
                    .foregroundStyle(color.opacity(0.95))
            }
            FlowChips(items: items, color: color)
        }
        .padding(RinklerSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Quick links (Jomo-style action tiles)

    private var quickLinks: some View {
        HStack(spacing: 12) {
            linkTile("Strict Mode", "Lock it and mean it", icon: "lock.shield.fill", route: .strictModeSetup)
            linkTile("Adjust limits", "Apps & cutoffs", icon: "slider.horizontal.3", route: .settings)
        }
    }

    private func linkTile(_ title: String, _ subtitle: String, icon: String, route: Route) -> some View {
        NavigationLink(value: route) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(RinklerColors.signalBlue)
                Text(title)
                    .font(RinklerFonts.sans(15, .semibold))
                    .foregroundStyle(RinklerColors.signalText)
                Text(subtitle)
                    .font(RinklerFonts.sans(11, .regular))
                    .foregroundStyle(RinklerColors.signalTextDim)
                    .lineLimit(1)
            }
            .padding(RinklerSpacing.md)
            .frame(maxWidth: .infinity, minHeight: 96, alignment: .leading)
            .signalCard(cornerRadius: 18)
        }
        .buttonStyle(.plain)
    }

    // MARK: Start

    private var startButton: some View {
        Button { onStart?() } label: {
            HStack(spacing: 8) {
                Image(systemName: "bolt.fill").font(.system(size: 15, weight: .bold))
                Text("Start \(duration)-min session")
                    .font(RinklerFonts.sans(18, .semibold))
            }
            .foregroundStyle(RinklerColors.signalOnInk)
            .frame(maxWidth: .infinity).frame(height: 56)
            .background(RinklerColors.signalInk)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.top, RinklerSpacing.xs)
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
    @AppStorage(RinklerConstants.blockAdsTrackersEnabledKey,
                store: UserDefaults(suiteName: RinklerConstants.appGroupID))
    private var blockAdsTrackers = true

    @StateObject private var selection = BlockSelectionStore()
    @EnvironmentObject private var strictMode: StrictModeStore
    @EnvironmentObject private var blockedApps: BlockedAppsStore
    @EnvironmentObject private var screenTime: ScreenTimeManager
    @State private var showAppPicker = false

    var body: some View {
        ZStack {
            SignalBackground()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: RinklerSpacing.md) {
                    SectionHeader(title: "Apps", subtitle: "Kill the doomscroll, keep the useful bits.")

                    adsCard

                    wholeAppSection

                    HStack(alignment: .firstTextBaseline) {
                        SectionHeader(title: "Block feeds", subtitle: "Keeps DMs, search & profiles where it can.")
                        Spacer()
                        StatusPill(text: "BETA", tone: RinklerColors.signalBlue)
                    }
                    .padding(.top, RinklerSpacing.sm)

                    ForEach(BlockCatalog.apps) { app in appCard(app) }

                    Text("Feed blocking runs on your phone — nothing leaves your device. Some apps blend the feed in with the useful stuff, so a few may block a bit more than just the feed; when that happens, lock the whole app instead. Precise per-feed blocking lands with iOS 26.")
                        .font(RinklerFonts.sans(12, .regular))
                        .foregroundStyle(RinklerColors.signalTextDim)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, RinklerSpacing.xs)
                }
                .padding(RinklerSpacing.lg)
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(nil)
    }

    private var wholeAppSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                SectionHeader(title: "Block whole apps", subtitle: "The hard block — like Opal.")
                Spacer()
                if blockedApps.enabled && screenTime.isAuthorized && blockedApps.appCount > 0 {
                    StatusPill(text: "ON", icon: "checkmark", tone: RinklerColors.signalSuccess)
                }
            }

            if !screenTime.isAuthorized {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Turn on Screen Time so Rinkler can hard-block whole apps and read your real usage.")
                        .font(RinklerFonts.sans(13, .regular))
                        .foregroundStyle(RinklerColors.signalTextDim)
                        .fixedSize(horizontal: false, vertical: true)
                    Button { Task { await screenTime.requestAccess(); blockedApps.apply() } } label: {
                        Text("Connect Screen Time")
                            .font(RinklerFonts.sans(15, .semibold))
                            .foregroundStyle(RinklerColors.signalOnInk)
                            .frame(maxWidth: .infinity).frame(height: 48)
                            .background(RinklerColors.signalInk)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .padding(RinklerSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .signalCard(cornerRadius: 16)
            } else {
                VStack(spacing: 10) {
                    #if canImport(FamilyControls)
                    Button { showAppPicker = true } label: {
                        HStack(spacing: RinklerSpacing.md) {
                            Image(systemName: "lock.shield.fill").foregroundStyle(RinklerColors.signalBlue)
                            Text(blockedApps.appCount == 0 ? "Pick apps to block" : "\(blockedApps.appCount) blocked")
                                .font(RinklerFonts.sans(15, .medium))
                                .foregroundStyle(RinklerColors.signalText)
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(RinklerColors.signalTextFaint)
                        }
                        .padding(RinklerSpacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .signalCard(cornerRadius: 14)
                    }
                    .buttonStyle(.plain)
                    .familyActivityPicker(isPresented: $showAppPicker,
                                          selection: Binding(get: { blockedApps.selection },
                                                             set: { blockedApps.setSelection($0) }))
                    #endif
                    Toggle(isOn: Binding(get: { blockedApps.enabled }, set: { blockedApps.setEnabled($0) })) {
                        Text("Block them now")
                            .font(RinklerFonts.sans(15, .medium))
                            .foregroundStyle(RinklerColors.signalText)
                    }
                    .tint(RinklerColors.signalBlue)
                    .disabled(strictMode.isActive)
                }
                .padding(RinklerSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .signalCard(cornerRadius: 16)
            }
        }
    }

    private var adsCard: some View {
        HStack(spacing: RinklerSpacing.md) {
            Image(systemName: "hand.raised.slash.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(RinklerColors.signalBlue)
            VStack(alignment: .leading, spacing: 2) {
                Text("Ads & trackers")
                    .font(RinklerFonts.sans(17, .semibold))
                    .foregroundStyle(RinklerColors.signalText)
                Text("Gone across every app while protection's on.")
                    .font(RinklerFonts.sans(12, .regular))
                    .foregroundStyle(RinklerColors.signalTextDim)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: RinklerSpacing.sm)
            Toggle("", isOn: $blockAdsTrackers).labelsHidden().tint(RinklerColors.signalBlue)
                .disabled(strictMode.isActive)
        }
        .padding(RinklerSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .signalCard(cornerRadius: 18)
    }

    private func appCard(_ app: BlockApp) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: app.symbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(RinklerColors.signalText)
                    .frame(width: 24)
                Text(app.name)
                    .font(RinklerFonts.sans(18, .semibold))
                    .foregroundStyle(RinklerColors.signalText)
                Spacer()
                if app.mostlyFeed {
                    StatusPill(text: "MOSTLY FEED", tone: RinklerColors.signalWarning)
                }
            }
            ForEach(app.features) { feature in
                Divider().overlay(RinklerColors.signalBorder)
                HStack(spacing: RinklerSpacing.md) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(feature.name)
                            .font(RinklerFonts.sans(15, .medium))
                            .foregroundStyle(RinklerColors.signalText)
                        Text(feature.blurb)
                            .font(RinklerFonts.sans(12, .regular))
                            .foregroundStyle(RinklerColors.signalTextDim)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: RinklerSpacing.sm)
                    Toggle("", isOn: Binding(
                        get: { selection.isOn(app.id, feature.id) },
                        set: { _ in selection.toggle(app.id, feature.id) }
                    ))
                    .labelsHidden().tint(RinklerColors.signalBlue)
                    .disabled(strictMode.isActive)
                }
            }
        }
        .padding(RinklerSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .signalCard(cornerRadius: 18)
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
    @EnvironmentObject private var strictMode: StrictModeStore
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
                            TextField("Name this rule", text: $draft.name)
                                .font(RinklerFonts.sans(17, .medium))
                                .foregroundStyle(RinklerColors.signalText)
                                .padding(12)
                                .background(RinklerColors.signalCard)
                                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(RinklerColors.signalBorder, lineWidth: 1))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }

                        Toggle(isOn: $draft.enabled) {
                            Text("Rule's on")
                                .font(RinklerFonts.sans(15, .medium))
                                .foregroundStyle(RinklerColors.signalText)
                        }
                        .tint(RinklerColors.signalBlue)
                        .disabled(strictMode.isActive)

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
                            .disabled(strictMode.isActive)
                        }

                        group("BLOCKS") { chips(blockedCatalog, list: \.blocked, color: RinklerColors.signalWarning) }
                        group("KEEPS OPEN") { chips(allowedCatalog, list: \.allowed, color: RinklerColors.signalSuccess) }

                        if strictMode.isActive {
                            Text("Strict Mode is on — rules are locked until the window ends.")
                                .font(RinklerFonts.sans(12, .regular))
                                .foregroundStyle(RinklerColors.signalTextDim)
                        }

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
                        .disabled(strictMode.isActive)
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
                        .disabled(strictMode.isActive)
                }
            }
            .preferredColorScheme(nil)
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
    @EnvironmentObject private var screenTime: ScreenTimeManager
    @State private var noiseBlocked = 0

    var body: some View {
        ZStack {
            SignalBackground()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: RinklerSpacing.lg) {
                    screenTimeSection

                    SectionHeader(title: "Scroll report", subtitle: "What you've dodged lately")

                    RinklerStatRow(stats: [
                        ("Pulls dodged", "\(noiseBlocked)", RinklerColors.signalBlue),
                        ("Streak", "\(sessions.streak)d", nil),
                        ("Focus hours", focusHoursLabel, nil),
                    ])
                    .padding(.vertical, RinklerSpacing.md)
                    .frame(maxWidth: .infinity)
                    .signalCard(cornerRadius: 20)

                    if !weekPoints.allSatisfy({ $0.value == 0 }) {
                        VStack(alignment: .leading, spacing: RinklerSpacing.sm) {
                            SectionHeader(title: "This week", subtitle: "Focused minutes, day by day")
                            SignalChart(points: weekPoints)
                        }
                        .padding(RinklerSpacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .signalCard(cornerRadius: 20)
                    } else {
                        Text("Empty for now. Start a session and your dodged scrolls + time saved land here.")
                            .font(RinklerFonts.sans(14, .regular))
                            .foregroundStyle(RinklerColors.signalTextDim)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(RinklerSpacing.md)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .signalCard(cornerRadius: 18)
                    }

                    ringsSection
                }
                .padding(RinklerSpacing.lg)
            }
        }
        .preferredColorScheme(nil)
        .onAppear(perform: loadStats)
    }

    /// Real per-app screen time for today, straight from Apple's DeviceActivity
    /// report (rendered out-of-process by the RinklerActivityReport extension).
    @ViewBuilder private var screenTimeSection: some View {
        if screenTime.isAuthorized {
            UsageReportView()
                .frame(maxWidth: .infinity, minHeight: 180, alignment: .leading)
                .signalCard(cornerRadius: 20)
        } else {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Your real screen time", subtitle: "Straight from iOS, once you connect it.")
                Button { Task { await screenTime.requestAccess() } } label: {
                    Text("Connect Screen Time")
                        .font(RinklerFonts.sans(15, .semibold))
                        .foregroundStyle(RinklerColors.signalOnInk)
                        .frame(maxWidth: .infinity).frame(height: 48)
                        .background(RinklerColors.signalInk)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(RinklerSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .signalCard(cornerRadius: 20)
        }
    }

    private var focusHoursLabel: String {
        let h = sessions.records.reduce(0.0) { $0 + $1.durationSeconds } / 3600
        return h >= 10 ? "\(Int(h))h" : String(format: "%.1fh", h)
    }

    private var weekPoints: [(label: String, value: Double)] {
        let cal = Calendar.current
        let fmt = DateFormatter(); fmt.dateFormat = "EEEEE"
        return (0..<7).reversed().map { offset in
            let day = cal.date(byAdding: .day, value: -offset, to: Date()) ?? Date()
            let mins = sessions.records
                .filter { cal.isDate($0.startedAt, inSameDayAs: day) }
                .reduce(0.0) { $0 + $1.durationSeconds } / 60
            return (fmt.string(from: day), mins)
        }
    }

    // MARK: Signal Rings (rewards)

    private struct RingLevel {
        let title: String
        let requirement: String
    }

    private let levels: [RingLevel] = [
        RingLevel(title: "First Signal", requirement: "Bank your first clean minutes"),
        RingLevel(title: "Double Ring", requirement: "Dodge 10 scroll pulls"),
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
        .signalCard(cornerRadius: 16)
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
