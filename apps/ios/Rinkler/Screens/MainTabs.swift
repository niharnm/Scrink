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
            RinklerColors.signalBackground.ignoresSafeArea()
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
            RinklerColors.signalBackground.ignoresSafeArea()
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

// MARK: - Progress tab (scroll report)

/// Scroll-specific report. Reads the tunnel's blocked counter from the shared
/// stats file when available; otherwise invites the user to start a session.
struct ProgressScreen: View {
    @EnvironmentObject private var focusSystem: FocusSystemStore
    @State private var noiseBlocked = 0

    var body: some View {
        ZStack {
            RinklerColors.signalBackground.ignoresSafeArea()
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
                }
                .padding(RinklerSpacing.lg)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear(perform: loadStats)
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
