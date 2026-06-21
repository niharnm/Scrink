import SwiftUI
import Combine

// MARK: - Onboarding option models
//
// Story-mode onboarding: the user builds their personal "Focus System". Each
// chapter is a question; the answers generate preset rules automatically so the
// app feels like it already understands them before they touch any settings.

enum Trap: String, Codable, CaseIterable, Identifiable {
    case igReels, ytShorts, tiktokFYP, igExplore, snapSpotlight, redditHome, xFeed, other
    var id: String { rawValue }
    var title: String {
        switch self {
        case .igReels: return "Instagram Reels"
        case .ytShorts: return "YouTube Shorts"
        case .tiktokFYP: return "TikTok For You"
        case .igExplore: return "Instagram Explore"
        case .snapSpotlight: return "Snapchat Spotlight"
        case .redditHome: return "Reddit Home Feed"
        case .xFeed: return "X / Twitter Feed"
        case .other: return "Something else"
        }
    }
    /// Short label used inside generated rules.
    var surface: String {
        switch self {
        case .igReels: return "Reels"
        case .ytShorts: return "Shorts"
        case .tiktokFYP: return "TikTok FYP"
        case .igExplore: return "Explore"
        case .snapSpotlight: return "Spotlight"
        case .redditHome: return "Reddit feed"
        case .xFeed: return "X feed"
        case .other: return "Other feeds"
        }
    }
}

enum KeepItem: String, Codable, CaseIterable, Identifiable {
    case messages, school, ytSearch, music, maps, calendar, family, productivity, emergency
    var id: String { rawValue }
    var title: String {
        switch self {
        case .messages: return "Messages / DMs"
        case .school: return "School apps"
        case .ytSearch: return "YouTube Search"
        case .music: return "Music"
        case .maps: return "Maps"
        case .calendar: return "Calendar"
        case .family: return "Family contacts"
        case .productivity: return "Productivity apps"
        case .emergency: return "Emergency apps"
        }
    }
}

enum Goal: String, Codable, CaseIterable, Identifiable {
    case homework, sleep, gym, creative, morning, lessDoom, schoolFocus, nightControl
    var id: String { rawValue }
    var title: String {
        switch self {
        case .homework: return "Homework"
        case .sleep: return "Sleep"
        case .gym: return "Gym / fitness"
        case .creative: return "Creative work"
        case .morning: return "Morning routine"
        case .lessDoom: return "Less doomscrolling"
        case .schoolFocus: return "Focus during school"
        case .nightControl: return "More control at night"
        }
    }
}

enum DangerTime: String, Codable, CaseIterable, Identifiable {
    case beforeSchool, duringSchool, afterSchool, homework, lateNight, inBed, weekends, bored
    var id: String { rawValue }
    var title: String {
        switch self {
        case .beforeSchool: return "Before school"
        case .duringSchool: return "During school"
        case .afterSchool: return "After school"
        case .homework: return "During homework"
        case .lateNight: return "Late night"
        case .inBed: return "In bed"
        case .weekends: return "Weekends"
        case .bored: return "When bored"
        }
    }
}

enum Difficulty: String, Codable, CaseIterable, Identifiable {
    case soft, normal, locked
    var id: String { rawValue }
    var title: String {
        switch self {
        case .soft: return "Soft Mode"
        case .normal: return "Normal Mode"
        case .locked: return "Locked Mode"
        }
    }
    var blurb: String {
        switch self {
        case .soft: return "Remind me first — I can still get through."
        case .normal: return "Block it, with short breaks if I really need them."
        case .locked: return "No excuses during a session."
        }
    }
}

// MARK: - Generated rule

/// A preset focus rule generated from the user's answers. Times are minutes from
/// midnight. `blocked`/`allowed` are surface labels shown in the UI; the network
/// tunnel approximates them via its domain + byte-threshold + QUIC mechanism.
struct FocusRule: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String
    var startMinute: Int
    var endMinute: Int
    var blocked: [String]
    var allowed: [String]
    var difficultyRaw: String
    var enabled: Bool = true

    var difficulty: Difficulty { Difficulty(rawValue: difficultyRaw) ?? .normal }
    var timeRangeLabel: String { "\(Self.clock(startMinute)) – \(Self.clock(endMinute))" }

    static func clock(_ minutes: Int) -> String {
        let m = ((minutes % 1440) + 1440) % 1440
        let h24 = m / 60
        let min = m % 60
        let period = h24 < 12 ? "AM" : "PM"
        var h12 = h24 % 12
        if h12 == 0 { h12 = 12 }
        return String(format: "%d:%02d %@", h12, min, period)
    }
}

// MARK: - Saved profile

struct FocusProfile: Codable {
    var traps: [String]
    var keeps: [String]
    var goals: [String]
    var dangerTimes: [String]
    var difficulty: String
    var rules: [FocusRule]
    var signalScore: Int
    var createdAt: Date
}

// MARK: - Store

/// Owns the onboarding draft, generates the preset rules, persists the resulting
/// Focus System, and gates whether onboarding shows at all (first-time users
/// only). Injected app-wide so the dashboard and Settings can read the rules and
/// reset onboarding for testing.
@MainActor
final class FocusSystemStore: ObservableObject {
    // Draft answers
    @Published var traps: Set<Trap> = []
    @Published var keeps: Set<KeepItem> = []
    @Published var goals: Set<Goal> = []
    @Published var dangerTimes: Set<DangerTime> = []
    @Published var difficulty: Difficulty = .normal

    @Published var chapter: Int = 0
    static let chapterCount = 9

    // Result
    @Published private(set) var rules: [FocusRule] = []
    @Published private(set) var signalScore: Int = 50
    @Published private(set) var hasCompletedOnboarding: Bool

    private let defaults = UserDefaults(suiteName: RinklerConstants.appGroupID)
    private enum Keys {
        static let completed = "hasCompletedOnboarding"
        static let profile = "focusProfile"
    }

    private let encoder: JSONEncoder = {
        let e = JSONEncoder(); e.dateEncodingStrategy = .iso8601; return e
    }()
    private let decoder: JSONDecoder = {
        let d = JSONDecoder(); d.dateDecodingStrategy = .iso8601; return d
    }()

    init() {
        let d = UserDefaults(suiteName: RinklerConstants.appGroupID)
        hasCompletedOnboarding = d?.bool(forKey: Keys.completed) ?? false
        loadProfile()
    }

    // MARK: Navigation

    var progress: Double { Double(chapter + 1) / Double(Self.chapterCount) }

    func next() {
        if chapter == 6 { generateSystem() } // leaving permission → reveal next
        if chapter < Self.chapterCount - 1 {
            withAnimation(.easeInOut(duration: 0.35)) { chapter += 1 }
        }
    }

    func back() {
        if chapter > 0 {
            withAnimation(.easeInOut(duration: 0.35)) { chapter -= 1 }
        }
    }

    /// Skip the remaining questions: generate from whatever is selected (plus
    /// safe defaults) and jump to the reveal.
    func skipToReveal() {
        generateSystem()
        withAnimation(.easeInOut(duration: 0.35)) { chapter = 7 }
    }

    func complete() {
        if rules.isEmpty { generateSystem() }
        hasCompletedOnboarding = true
        defaults?.set(true, forKey: Keys.completed)
    }

    /// Resets onboarding (Settings → for testing). Clears the saved profile.
    func resetOnboarding() {
        hasCompletedOnboarding = false
        chapter = 0
        traps = []; keeps = []; goals = []; dangerTimes = []; difficulty = .normal
        rules = []; signalScore = 50
        defaults?.set(false, forKey: Keys.completed)
        defaults?.removeObject(forKey: Keys.profile)
    }

    // MARK: Rule generation

    /// Builds up to three named preset rules from the answers. Deterministic so
    /// the same answers always produce the same system.
    func generateSystem() {
        let trapSurfaces = traps.isEmpty ? ["Reels", "Shorts", "TikTok FYP"] : traps.map(\.surface)
        let allowBase = keeps.isEmpty ? ["Messages", "Search"] : keeps.map(\.title)

        var built: [FocusRule] = []

        func makeRule(_ name: String, _ start: Int, _ end: Int, extraBlocked: [String], allowed: [String], difficulty: Difficulty) {
            let blocked = Array(Set(trapSurfaces + extraBlocked)).sorted()
            built.append(FocusRule(name: name, startMinute: start, endMinute: end,
                                   blocked: blocked, allowed: allowed, difficultyRaw: difficulty.rawValue))
        }

        if goals.contains(.homework) || goals.contains(.schoolFocus) || dangerTimes.contains(.homework) || dangerTimes.contains(.afterSchool) {
            makeRule("Homework Mode", 19 * 60, 22 * 60,
                     extraBlocked: ["Explore"],
                     allowed: uniqueAllowed(allowBase + ["DMs", "YouTube Search", "School apps", "Music"]),
                     difficulty: difficulty)
        }

        if goals.contains(.sleep) || goals.contains(.nightControl) || dangerTimes.contains(.lateNight) || dangerTimes.contains(.inBed) {
            makeRule("Night Lock", 22 * 60 + 30, 7 * 60,
                     extraBlocked: ["Spotlight", "Reddit feed"],
                     allowed: ["Messages", "Phone", "Alarm", "Family contacts"],
                     difficulty: .locked)
        }

        if goals.contains(.schoolFocus) || dangerTimes.contains(.duringSchool) || dangerTimes.contains(.beforeSchool) {
            makeRule("School Mode", 8 * 60, 15 * 60 + 30,
                     extraBlocked: [],
                     allowed: uniqueAllowed(allowBase + ["School apps", "Messages", "Maps"]),
                     difficulty: difficulty == .locked ? .normal : difficulty)
        }

        if goals.contains(.morning) || dangerTimes.contains(.beforeSchool) {
            makeRule("Morning Clean Start", 6 * 60 + 30, 8 * 60,
                     extraBlocked: [],
                     allowed: uniqueAllowed(allowBase + ["Messages", "Calendar"]),
                     difficulty: .soft)
        }

        // Always leave the user with at least one rule.
        if built.isEmpty {
            makeRule("Focus Mode", 18 * 60, 21 * 60,
                     extraBlocked: [],
                     allowed: uniqueAllowed(allowBase + ["Messages"]),
                     difficulty: difficulty)
        }

        // De-dupe by name, cap at three so the reveal stays clean.
        var seen = Set<String>()
        rules = built.filter { seen.insert($0.name).inserted }.prefix(3).map { $0 }
        signalScore = 50
        persist()
    }

    private func uniqueAllowed(_ items: [String]) -> [String] {
        var seen = Set<String>()
        return items.filter { seen.insert($0).inserted }
    }

    // MARK: Persistence

    private func persist() {
        let profile = FocusProfile(
            traps: traps.map(\.rawValue),
            keeps: keeps.map(\.rawValue),
            goals: goals.map(\.rawValue),
            dangerTimes: dangerTimes.map(\.rawValue),
            difficulty: difficulty.rawValue,
            rules: rules,
            signalScore: signalScore,
            createdAt: Date()
        )
        if let data = try? encoder.encode(profile) {
            defaults?.set(data, forKey: Keys.profile)
        }
    }

    private func loadProfile() {
        guard let data = defaults?.data(forKey: Keys.profile),
              let profile = try? decoder.decode(FocusProfile.self, from: data) else { return }
        rules = profile.rules
        signalScore = profile.signalScore
        traps = Set(profile.traps.compactMap(Trap.init))
        keeps = Set(profile.keeps.compactMap(KeepItem.init))
        goals = Set(profile.goals.compactMap(Goal.init))
        dangerTimes = Set(profile.dangerTimes.compactMap(DangerTime.init))
        difficulty = Difficulty(rawValue: profile.difficulty) ?? .normal
    }
}

// MARK: - Signal Ring

/// The app's signature visual — a thin blue→violet ring that fills with progress.
/// Deliberately a clean "signal/control-panel" object, not an Opal-style gem/orb.
struct SignalRing<Center: View>: View {
    var progress: Double
    var lineWidth: CGFloat = 14
    @ViewBuilder var center: () -> Center

    init(progress: Double, lineWidth: CGFloat = 14, @ViewBuilder center: @escaping () -> Center = { EmptyView() }) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.center = center
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(RinklerColors.signalBorder, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, min(1, progress)))
                .stroke(RinklerColors.signalGlow,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: RinklerColors.signalBlue.opacity(0.45), radius: 14)
                .animation(.easeInOut(duration: 0.5), value: progress)
            center()
        }
    }
}

// MARK: - Selectable chip

private struct SelectChip: View {
    let label: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(RinklerFonts.sans(15, .medium))
                .foregroundStyle(selected ? RinklerColors.signalText : RinklerColors.signalTextDim)
                .padding(.horizontal, RinklerSpacing.md)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(selected ? RinklerColors.signalCardRaised : RinklerColors.signalCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(selected ? RinklerColors.signalBlue : RinklerColors.signalBorder,
                                      lineWidth: selected ? 1.5 : 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Onboarding flow

struct OnboardingFlow: View {
    @EnvironmentObject private var focusSystem: FocusSystemStore
    @EnvironmentObject private var vpnManager: VPNManager
    var onFinish: () -> Void

    @State private var showSkipWarning = false

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ZStack {
            RinklerColors.signalBackground.ignoresSafeArea()

            VStack(spacing: RinklerSpacing.lg) {
                header

                ScrollView(showsIndicators: false) {
                    chapterContent
                        .padding(.horizontal, RinklerSpacing.lg)
                        .padding(.top, RinklerSpacing.sm)
                        .id(focusSystem.chapter)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }

                footer
            }
            .padding(.vertical, RinklerSpacing.lg)
        }
        .preferredColorScheme(.dark)
        .alert("Skip personalization?", isPresented: $showSkipWarning) {
            Button("Keep going", role: .cancel) {}
            Button("Skip") { focusSystem.skipToReveal() }
        } message: {
            Text("We'll set up safe defaults, but the system won't be tuned to you. You can always edit rules later.")
        }
    }

    // MARK: Header (progress + signal ring)

    private var header: some View {
        HStack(spacing: RinklerSpacing.md) {
            if focusSystem.chapter > 0 {
                Button { focusSystem.back() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(RinklerColors.signalTextDim)
                        .frame(width: 36, height: 36)
                        .background(RinklerColors.signalCard)
                        .clipShape(Circle())
                }
            }

            SignalRing(progress: focusSystem.progress, lineWidth: 4)
                .frame(width: 34, height: 34)

            Text("Chapter \(focusSystem.chapter + 1) of \(FocusSystemStore.chapterCount)")
                .font(RinklerFonts.sans(13, .medium))
                .foregroundStyle(RinklerColors.signalTextDim)

            Spacer()

            if focusSystem.chapter < 7 {
                Button("Skip") { showSkipWarning = true }
                    .font(RinklerFonts.sans(13, .medium))
                    .foregroundStyle(RinklerColors.signalTextDim)
            }
        }
        .padding(.horizontal, RinklerSpacing.lg)
    }

    // MARK: Chapter router

    @ViewBuilder private var chapterContent: some View {
        switch focusSystem.chapter {
        case 0: hookChapter
        case 1: trapsChapter
        case 2: keepChapter
        case 3: goalChapter
        case 4: dangerChapter
        case 5: difficultyChapter
        case 6: permissionChapter
        case 7: revealChapter
        default: firstWinChapter
        }
    }

    // MARK: Chapters

    private var hookChapter: some View {
        VStack(alignment: .leading, spacing: RinklerSpacing.md) {
            Spacer(minLength: RinklerSpacing.xl)
            Text("Your phone isn't the problem.\nThe infinite scroll is.")
                .font(RinklerFonts.sans(34, .bold))
                .foregroundStyle(RinklerColors.signalText)
                .fixedSize(horizontal: false, vertical: true)
            Text("We'll help you keep the useful parts of your apps — DMs, search, messages — and block the parts designed to pull you in.")
                .font(RinklerFonts.sans(16, .regular))
                .foregroundStyle(RinklerColors.signalTextDim)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: RinklerSpacing.xl)
        }
    }

    private var trapsChapter: some View {
        chapterScaffold(title: "Which parts pull you in the most?",
                        subtitle: "Pick all that apply. These are the surfaces we'll cut.") {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(Trap.allCases) { trap in
                    SelectChip(label: trap.title, selected: focusSystem.traps.contains(trap)) {
                        toggle(trap, in: \.traps)
                    }
                }
            }
        }
    }

    private var keepChapter: some View {
        chapterScaffold(title: "What should always stay available?",
                        subtitle: "We're not deleting your phone — we separate useful from addictive.") {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(KeepItem.allCases) { item in
                    SelectChip(label: item.title, selected: focusSystem.keeps.contains(item)) {
                        toggle(item, in: \.keeps)
                    }
                }
            }
        }
    }

    private var goalChapter: some View {
        chapterScaffold(title: "What are you trying to protect?",
                        subtitle: "Pick what matters most right now.") {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(Goal.allCases) { goal in
                    SelectChip(label: goal.title, selected: focusSystem.goals.contains(goal)) {
                        toggle(goal, in: \.goals)
                    }
                }
            }
        }
    }

    private var dangerChapter: some View {
        chapterScaffold(title: "When do you usually lose control?",
                        subtitle: "We'll guard these windows automatically.") {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(DangerTime.allCases) { time in
                    SelectChip(label: time.title, selected: focusSystem.dangerTimes.contains(time)) {
                        toggle(time, in: \.dangerTimes)
                    }
                }
            }
        }
    }

    private var difficultyChapter: some View {
        chapterScaffold(title: "How strict should we be?",
                        subtitle: "You can change this per rule later.") {
            VStack(spacing: 12) {
                ForEach(Difficulty.allCases) { level in
                    Button { focusSystem.difficulty = level } label: {
                        HStack(alignment: .top, spacing: RinklerSpacing.md) {
                            Image(systemName: focusSystem.difficulty == level ? "largecircle.fill.circle" : "circle")
                                .foregroundStyle(focusSystem.difficulty == level ? RinklerColors.signalBlue : RinklerColors.signalTextDim)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(level.title)
                                    .font(RinklerFonts.sans(17, .semibold))
                                    .foregroundStyle(RinklerColors.signalText)
                                Text(level.blurb)
                                    .font(RinklerFonts.sans(13, .regular))
                                    .foregroundStyle(RinklerColors.signalTextDim)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer()
                        }
                        .padding(RinklerSpacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RinklerColors.signalCard)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(focusSystem.difficulty == level ? RinklerColors.signalBlue : RinklerColors.signalBorder,
                                              lineWidth: focusSystem.difficulty == level ? 1.5 : 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var permissionChapter: some View {
        chapterScaffold(title: "Arm your attention shield",
                        subtitle: "Rinkler filters traffic locally on this device — nothing leaves your phone. iOS will ask to add a VPN configuration. That's what does the blocking.") {
            VStack(spacing: RinklerSpacing.md) {
                SignalRing(progress: 0.66, lineWidth: 10) {
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundStyle(RinklerColors.signalBlue)
                }
                .frame(width: 150, height: 150)
                .padding(.vertical, RinklerSpacing.md)

                Text("Allow it on the next screen so your rules can actually hold.")
                    .font(RinklerFonts.sans(14, .regular))
                    .foregroundStyle(RinklerColors.signalTextDim)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var revealChapter: some View {
        chapterScaffold(title: "Your Focus System is ready.",
                        subtitle: rulesSummaryLine) {
            VStack(spacing: RinklerSpacing.lg) {
                SignalRing(progress: Double(focusSystem.signalScore) / 100.0, lineWidth: 12) {
                    VStack(spacing: 0) {
                        Text("\(focusSystem.signalScore)")
                            .font(RinklerFonts.mono(40, .medium))
                            .foregroundStyle(RinklerColors.signalText)
                        Text("Signal Score")
                            .font(RinklerFonts.sans(11, .medium))
                            .foregroundStyle(RinklerColors.signalTextDim)
                    }
                }
                .frame(width: 150, height: 150)

                VStack(spacing: 12) {
                    ForEach(focusSystem.rules) { rule in
                        ruleCard(rule)
                    }
                }
            }
        }
    }

    private var firstWinChapter: some View {
        VStack(spacing: RinklerSpacing.md) {
            Spacer(minLength: RinklerSpacing.xl)
            SignalRing(progress: 1, lineWidth: 12) {
                Image(systemName: "checkmark")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(RinklerColors.signalSuccess)
            }
            .frame(width: 150, height: 150)

            Text("First Signal Ring unlocked")
                .font(RinklerFonts.sans(22, .semibold))
                .foregroundStyle(RinklerColors.signalText)
            Text("Setup Complete. Start with 10 minutes and win your first ring.")
                .font(RinklerFonts.sans(15, .regular))
                .foregroundStyle(RinklerColors.signalTextDim)
                .multilineTextAlignment(.center)
                .padding(.horizontal, RinklerSpacing.lg)
            Spacer(minLength: RinklerSpacing.xl)
        }
    }

    // MARK: Footer CTA (one primary action per screen)

    @ViewBuilder private var footer: some View {
        VStack(spacing: 0) {
            primaryButton(ctaTitle) { handlePrimary() }
        }
        .padding(.horizontal, RinklerSpacing.lg)
    }

    private var ctaTitle: String {
        switch focusSystem.chapter {
        case 0: return "Build My Focus System"
        case 6: return "Allow & Continue"
        case 7: return "Start First Win"
        case 8: return "Start First Session"
        default: return "Continue"
        }
    }

    private func handlePrimary() {
        switch focusSystem.chapter {
        case 6:
            vpnManager.requestPermission()
            focusSystem.next()
        case 8:
            focusSystem.complete()
            onFinish()
        default:
            focusSystem.next()
        }
    }

    // MARK: Building blocks

    private func chapterScaffold<Content: View>(title: String, subtitle: String,
                                                @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: RinklerSpacing.md) {
            Text(title)
                .font(RinklerFonts.sans(28, .bold))
                .foregroundStyle(RinklerColors.signalText)
                .fixedSize(horizontal: false, vertical: true)
            Text(subtitle)
                .font(RinklerFonts.sans(15, .regular))
                .foregroundStyle(RinklerColors.signalTextDim)
                .fixedSize(horizontal: false, vertical: true)
            content()
                .padding(.top, RinklerSpacing.sm)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func ruleCard(_ rule: FocusRule) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(rule.name)
                    .font(RinklerFonts.sans(17, .semibold))
                    .foregroundStyle(RinklerColors.signalText)
                Spacer()
                Text(rule.difficulty.title)
                    .font(RinklerFonts.sans(11, .medium))
                    .foregroundStyle(RinklerColors.signalBlue)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(RinklerColors.signalBlue.opacity(0.12))
                    .clipShape(Capsule())
            }
            Text(rule.timeRangeLabel)
                .font(RinklerFonts.mono(13, .regular))
                .foregroundStyle(RinklerColors.signalTextDim)
            Text("Blocks " + rule.blocked.prefix(4).joined(separator: ", "))
                .font(RinklerFonts.sans(12, .regular))
                .foregroundStyle(RinklerColors.signalTextDim)
            Text("Keeps " + rule.allowed.prefix(4).joined(separator: ", "))
                .font(RinklerFonts.sans(12, .regular))
                .foregroundStyle(RinklerColors.signalSuccess.opacity(0.85))
        }
        .padding(RinklerSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RinklerColors.signalCard)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(RinklerColors.signalBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func primaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(RinklerFonts.sans(18, .semibold))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(RinklerColors.signalGlow)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var rulesSummaryLine: String {
        let n = focusSystem.rules.count
        let names = focusSystem.rules.map(\.name).joined(separator: ", ")
        return "Based on your answers, we created \(n) rule\(n == 1 ? "" : "s"): \(names)."
    }

    // MARK: Selection helpers

    private func toggle<T: Hashable>(_ value: T, in keyPath: ReferenceWritableKeyPath<FocusSystemStore, Set<T>>) {
        if focusSystem[keyPath: keyPath].contains(value) {
            focusSystem[keyPath: keyPath].remove(value)
        } else {
            focusSystem[keyPath: keyPath].insert(value)
        }
    }
}

// MARK: - Today dashboard (post-onboarding home in the Signal identity)

/// The screen the user lands on after onboarding. It shows their Signal Score,
/// the rules their answers generated, the next scheduled window, and one primary
/// action — so the app feels already set up before they touch any settings.
struct TodayDashboard: View {
    @EnvironmentObject private var focusSystem: FocusSystemStore
    @EnvironmentObject private var vpnManager: VPNManager

    var onSettings: (() -> Void)? = nil
    var onStartSession: (() -> Void)? = nil
    var onTrafficDashboard: (() -> Void)? = nil

    var body: some View {
        ZStack {
            RinklerColors.signalBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: RinklerSpacing.lg) {
                    header
                    scoreCard
                    nextWindowCard
                    rulesSection
                    protectionRow
                }
                .padding(.horizontal, RinklerSpacing.lg)
                .padding(.top, RinklerSpacing.lg)
                .padding(.bottom, RinklerSpacing.xxl)
            }
        }
        .navigationBarBackButtonHidden(true)
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("TODAY")
                    .font(RinklerFonts.sans(13, .semibold))
                    .foregroundStyle(RinklerColors.signalTextDim)
                Text("Your Focus System")
                    .font(RinklerFonts.sans(24, .bold))
                    .foregroundStyle(RinklerColors.signalText)
            }
            Spacer()
            iconButton("chart.bar.fill", action: onTrafficDashboard)
            iconButton("gearshape.fill", action: onSettings)
        }
    }

    private var scoreCard: some View {
        HStack(spacing: RinklerSpacing.lg) {
            SignalRing(progress: Double(focusSystem.signalScore) / 100.0, lineWidth: 10) {
                VStack(spacing: 0) {
                    Text("\(focusSystem.signalScore)")
                        .font(RinklerFonts.mono(30, .medium))
                        .foregroundStyle(RinklerColors.signalText)
                    Text("Signal")
                        .font(RinklerFonts.sans(10, .medium))
                        .foregroundStyle(RinklerColors.signalTextDim)
                }
            }
            .frame(width: 104, height: 104)

            VStack(alignment: .leading, spacing: 6) {
                Text("Scroll Control")
                    .font(RinklerFonts.sans(17, .semibold))
                    .foregroundStyle(RinklerColors.signalText)
                Text("Your system is armed. Start a session to win your first ring and push the score up.")
                    .font(RinklerFonts.sans(13, .regular))
                    .foregroundStyle(RinklerColors.signalTextDim)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(RinklerSpacing.lg)
        .background(RinklerColors.signalCard)
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(RinklerColors.signalBorder, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var nextWindowCard: some View {
        Button { onStartSession?() } label: {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(nextRule != nil ? "Next window" : "Suggested")
                        .font(RinklerFonts.sans(12, .medium))
                        .foregroundStyle(RinklerColors.signalTextDim)
                    Text(nextRule?.name ?? "Start a 10-minute Control Session")
                        .font(RinklerFonts.sans(18, .semibold))
                        .foregroundStyle(RinklerColors.signalText)
                    if let rule = nextRule {
                        Text(rule.timeRangeLabel)
                            .font(RinklerFonts.mono(12, .regular))
                            .foregroundStyle(RinklerColors.signalTextDim)
                    }
                }
                Spacer()
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(RinklerColors.signalBlue)
            }
            .padding(RinklerSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RinklerColors.signalBlue.opacity(0.12))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(RinklerColors.signalBlue.opacity(0.4), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var rulesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RULES")
                .font(RinklerFonts.sans(12, .semibold))
                .foregroundStyle(RinklerColors.signalTextDim)
            if focusSystem.rules.isEmpty {
                Text("No rules yet — re-run setup from Settings to generate them.")
                    .font(RinklerFonts.sans(13, .regular))
                    .foregroundStyle(RinklerColors.signalTextDim)
            } else {
                ForEach(focusSystem.rules) { rule in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(rule.name)
                                .font(RinklerFonts.sans(16, .semibold))
                                .foregroundStyle(RinklerColors.signalText)
                            Spacer()
                            Text(rule.difficulty.title)
                                .font(RinklerFonts.sans(11, .medium))
                                .foregroundStyle(RinklerColors.signalBlue)
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(RinklerColors.signalBlue.opacity(0.12))
                                .clipShape(Capsule())
                        }
                        Text(rule.timeRangeLabel)
                            .font(RinklerFonts.mono(12, .regular))
                            .foregroundStyle(RinklerColors.signalTextDim)
                        Text("Blocks " + rule.blocked.prefix(4).joined(separator: ", "))
                            .font(RinklerFonts.sans(12, .regular))
                            .foregroundStyle(RinklerColors.signalTextDim)
                    }
                    .padding(RinklerSpacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RinklerColors.signalCard)
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(RinklerColors.signalBorder, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }
        }
    }

    private var protectionRow: some View {
        HStack(spacing: RinklerSpacing.md) {
            Image(systemName: vpnManager.vpnStatus == .connected ? "shield.lefthalf.filled" : "shield.slash")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(vpnManager.vpnStatus == .connected ? RinklerColors.signalSuccess : RinklerColors.signalTextDim)
            Text(vpnManager.vpnStatus == .connected ? "Protection on" : "Protection off")
                .font(RinklerFonts.sans(15, .medium))
                .foregroundStyle(RinklerColors.signalText)
            Spacer()
            Button { vpnManager.toggleVPN() } label: {
                Text(vpnManager.vpnStatus == .connected ? "Stop" : "Start")
                    .font(RinklerFonts.sans(14, .semibold))
                    .foregroundStyle(vpnManager.vpnStatus == .connected ? RinklerColors.signalText : .black)
                    .padding(.horizontal, 18).frame(height: 36)
                    .background(vpnManager.vpnStatus == .connected ? AnyView(RinklerColors.signalCardRaised) : AnyView(RinklerColors.signalGlow))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(vpnManager.isPreparingProfile)
        }
        .padding(RinklerSpacing.md)
        .background(RinklerColors.signalCard)
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(RinklerColors.signalBorder, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    /// The first rule whose window hasn't ended yet today (simple heuristic until
    /// the scheduler backend lands).
    private var nextRule: FocusRule? {
        let now = Calendar.current
        let minutes = now.component(.hour, from: Date()) * 60 + now.component(.minute, from: Date())
        return focusSystem.rules
            .sorted { $0.startMinute < $1.startMinute }
            .first { $0.endMinute > minutes } ?? focusSystem.rules.first
    }

    private func iconButton(_ systemName: String, action: (() -> Void)?) -> some View {
        Button { action?() } label: {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(RinklerColors.signalText)
                .frame(width: 40, height: 40)
                .background(RinklerColors.signalCard)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }
}
