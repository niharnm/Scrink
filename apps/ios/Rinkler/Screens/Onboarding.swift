import SwiftUI
import Combine
import AuthenticationServices
import UserNotifications

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
        case .soft: return "Nudge me first. I can still get through if I mean it."
        case .normal: return "Block it. Short breaks if I really need them."
        case .locked: return "No way out mid-session. Don't even ask."
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
    static let chapterCount = 11

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

        #if DEBUG
        // Screenshot/QA hook: -obChapter N jumps onboarding to a chapter.
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-obChapter"), i + 1 < args.count, let n = Int(args[i + 1]) {
            chapter = max(0, min(n, Self.chapterCount - 1))
        }
        #endif
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

    /// Clears the auto-generated presets so the user can start from a blank slate
    /// and build their own rules. Used by the post-reveal "pick my own" option.
    func clearRules() {
        guard !StrictModeStore.isActivePersisted else { return }
        rules = []
        signalScore = 50
        persist()
    }

    /// Resets onboarding (Settings → for testing). Clears the saved profile.
    func resetOnboarding() {
        guard !StrictModeStore.isActivePersisted else { return }
        hasCompletedOnboarding = false
        chapter = 0
        traps = []; keeps = []; goals = []; dangerTimes = []; difficulty = .normal
        rules = []; signalScore = 50
        defaults?.set(false, forKey: Keys.completed)
        defaults?.removeObject(forKey: Keys.profile)
        defaults?.removeObject(forKey: "ruleSchedule")
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

    // MARK: Rule editing

    /// Replaces a rule (matched by id), or appends it if new. Re-persists and
    /// re-emits the tunnel schedule.
    func updateRule(_ rule: FocusRule) {
        guard !StrictModeStore.isActivePersisted else { return }
        if let idx = rules.firstIndex(where: { $0.id == rule.id }) {
            rules[idx] = rule
        } else {
            rules.append(rule)
        }
        persist()
    }

    func deleteRule(_ id: UUID) {
        guard !StrictModeStore.isActivePersisted else { return }
        rules.removeAll { $0.id == id }
        persist()
    }

    func addBlankRule() {
        rules.append(FocusRule(
            name: "New Rule",
            startMinute: 20 * 60,
            endMinute: 22 * 60,
            blocked: ["Reels", "Shorts", "TikTok FYP"],
            allowed: ["Messages"],
            difficultyRaw: difficulty.rawValue
        ))
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
        writeSchedule()
    }

    /// Compact schedule window the tunnel reads (keys must match `ScheduleWindow`
    /// in the tunnel target).
    private struct ScheduleWindowOut: Codable {
        let start: Int
        let end: Int
        let ig: Bool
        let tt: Bool
        let th: Int
    }

    /// Translates the generated rules into the schedule the packet tunnel
    /// evaluates so blocking holds on time without the app being open.
    private func writeSchedule() {
        let instagramSurfaces: Set<String> = ["Reels", "Explore"]
        let windows: [ScheduleWindowOut] = rules.filter { $0.enabled }.map { rule in
            let blocked = Set(rule.blocked)
            let threshold: Int
            switch rule.difficulty {
            case .soft: threshold = 1_572_864   // 1.5 MB — only the heaviest
            case .normal: threshold = 512 * 1024 // 0.5 MB
            case .locked: threshold = 0          // block immediately
            }
            return ScheduleWindowOut(
                start: rule.startMinute,
                end: rule.endMinute,
                ig: !blocked.isDisjoint(with: instagramSurfaces),
                tt: blocked.contains("TikTok FYP"),
                th: threshold
            )
        }
        if let data = try? JSONEncoder().encode(windows) {
            defaults?.set(data, forKey: "ruleSchedule")
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
                .stroke(RinklerColors.signalBlue,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
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

// MARK: - Google glyph

/// A lightweight "G" mark for the Google button. Drop the official multicolor
/// asset in `Assets.xcassets` (named "google-logo") and swap this for an
/// `Image("google-logo")` when brand assets are available.
private struct GoogleGlyph: View {
    var body: some View {
        Text("G")
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .foregroundStyle(Color(red: 0.26, green: 0.52, blue: 0.96)) // Google blue
            .frame(width: 20, height: 20)
    }
}

// MARK: - Onboarding flow

struct OnboardingFlow: View {
    @EnvironmentObject private var focusSystem: FocusSystemStore
    @EnvironmentObject private var vpnManager: VPNManager
    @Environment(AuthStore.self) private var authStore
    var onFinish: () -> Void

    @State private var showSkipWarning = false
    @State private var social = SocialAuthService()
    @State private var authButtonsShown = false
    @State private var showPresetPopup = false
    @State private var presetPopupSeen = false

    /// The account step sits second-to-last: after the reveal (so the user sees
    /// their generated system first), before the final "first win" screen.
    private var authChapterIndex: Int { FocusSystemStore.chapterCount - 2 }

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ZStack {
            SignalBackground()

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
        .preferredColorScheme(nil)
        .alert("Skip the questions?", isPresented: $showSkipWarning) {
            Button("Nah, keep going", role: .cancel) {}
            Button("Skip") { focusSystem.skipToReveal() }
        } message: {
            Text("You'll get safe defaults, just not tuned to you. You can mess with the rules later anyway.")
        }
        .onChange(of: focusSystem.chapter) { _, newValue in
            // One-time, right after the presets reveal: offer to clear them.
            if newValue == 7 && !presetPopupSeen {
                presetPopupSeen = true
                withAnimation(.easeOut(duration: 0.25)) { showPresetPopup = true }
            }
        }
        .overlay {
            if showPresetPopup { presetPopup }
        }
    }

    // MARK: Remove-presets popup (transient, shown once after the reveal)

    private var presetPopup: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { withAnimation { showPresetPopup = false } }

            VStack(spacing: RinklerSpacing.md) {
                Text("Made from your answers")
                    .font(RinklerFonts.sans(19, .bold))
                    .foregroundStyle(RinklerColors.signalText)
                    .multilineTextAlignment(.center)
                Text("Not feeling these? Wipe them and build your own. Your call.")
                    .font(RinklerFonts.sans(14, .regular))
                    .foregroundStyle(RinklerColors.signalTextDim)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 10) {
                    Button { withAnimation { showPresetPopup = false } } label: {
                        Text("These are good")
                            .font(RinklerFonts.sans(16, .semibold))
                            .foregroundStyle(RinklerColors.signalOnInk)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(RinklerColors.signalInk)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Button {
                        focusSystem.clearRules()
                        withAnimation { showPresetPopup = false }
                    } label: {
                        Text("Nah, I'll build my own")
                            .font(RinklerFonts.sans(15, .medium))
                            .foregroundStyle(RinklerColors.signalTextDim)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, RinklerSpacing.sm)
            }
            .padding(RinklerSpacing.lg)
            .frame(maxWidth: 340)
            .background(RinklerColors.signalCard)
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(RinklerColors.signalBorder, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .padding(RinklerSpacing.lg)
        }
        .transition(.opacity)
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

            Text("Step \(focusSystem.chapter + 1) of \(FocusSystemStore.chapterCount)")
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
        case 8: notificationsChapter
        case 9: authChapter
        default: firstWinChapter
        }
    }

    // MARK: Chapters

    private var hookChapter: some View {
        VStack(alignment: .leading, spacing: RinklerSpacing.md) {
            Spacer(minLength: RinklerSpacing.lg)
            Text("Your phone's fine.\nThe infinite scroll isn't.")
                .font(RinklerFonts.sans(34, .bold))
                .foregroundStyle(RinklerColors.signalText)
                .fixedSize(horizontal: false, vertical: true)
            Text("This takes a minute. We'll find what's eating your time, then kill the endless feeds while leaving the stuff you actually use — DMs, search, all that — alone.")
                .font(RinklerFonts.sans(16, .regular))
                .foregroundStyle(RinklerColors.signalTextDim)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: RinklerSpacing.lg)

            // Signature hero ring — anchors the screen instead of an empty void.
            SignalRing(progress: 0.66, lineWidth: 12) {
                Image(systemName: "scope")
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(RinklerColors.signalBlue)
            }
            .frame(width: 190, height: 190)
            .frame(maxWidth: .infinity)

            Spacer(minLength: RinklerSpacing.lg)
        }
    }

    private var trapsChapter: some View {
        chapterScaffold(title: "What sucks you in the most?",
                        subtitle: "Pick whatever's true. These are the parts we kill.") {
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
        chapterScaffold(title: "What do you want to keep?",
                        subtitle: "We're not nuking your apps, just the time-sink parts. The rest stays.") {
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
        chapterScaffold(title: "What are you trying to get back?",
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
        chapterScaffold(title: "When do you usually fall in?",
                        subtitle: "We'll lock these times down on their own, no thinking required.") {
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
        chapterScaffold(title: "How hard should we go?",
                        subtitle: "Change it whenever. No big deal.") {
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
        chapterScaffold(title: "Quick heads up about the “VPN”",
                        subtitle: "To block stuff inside your apps, Rinkler runs a filter right here on your phone. iOS makes any on-device filter show up as a “VPN,” so the next tap asks to add one — but it's not a real VPN: nothing leaves your phone and we can't see your traffic. While it's on it also quietly kills ads and trackers. And it's not always-on — it only runs while you're protected and switches itself off when a session ends, so it's not sitting in the background.") {
            VStack(spacing: RinklerSpacing.md) {
                SignalRing(progress: 0.66, lineWidth: 10) {
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundStyle(RinklerColors.signalBlue)
                }
                .frame(width: 150, height: 150)
                .padding(.vertical, RinklerSpacing.md)

                Text("Tap below, then hit Allow when iOS asks. That's the part that lets Rinkler actually block stuff.")
                    .font(RinklerFonts.sans(14, .regular))
                    .foregroundStyle(RinklerColors.signalTextDim)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var revealChapter: some View {
        chapterScaffold(title: "Done. Here's your setup.",
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
        .onAppear {
            if !presetPopupSeen {
                presetPopupSeen = true
                withAnimation(.easeOut(duration: 0.25)) { showPresetPopup = true }
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

            Text("Nice. First ring earned.")
                .font(RinklerFonts.sans(22, .semibold))
                .foregroundStyle(RinklerColors.signalText)
            Text("You're set up. Do 10 minutes and grab your first ring.")
                .font(RinklerFonts.sans(15, .regular))
                .foregroundStyle(RinklerColors.signalTextDim)
                .multilineTextAlignment(.center)
                .padding(.horizontal, RinklerSpacing.lg)
            Spacer(minLength: RinklerSpacing.xl)
        }
    }

    // MARK: Notifications chapter

    private var notificationsChapter: some View {
        chapterScaffold(title: "Want a couple of useful pings?",
                        subtitle: "Two kinds, that's it: a heads-up right before a focus window starts, and a quick “you earned a ring” when you win one. No spam, no guilt-trips, no “you've been on your phone 3 hours” shaming.") {
            VStack(spacing: RinklerSpacing.md) {
                SignalRing(progress: 0.66, lineWidth: 10) {
                    Image(systemName: "bell.badge")
                        .font(.system(size: 38, weight: .semibold))
                        .foregroundStyle(RinklerColors.signalBlue)
                }
                .frame(width: 150, height: 150)
                .padding(.vertical, RinklerSpacing.md)

                Button { focusSystem.next() } label: {
                    Text("Maybe later")
                        .font(RinklerFonts.sans(15, .medium))
                        .foregroundStyle(RinklerColors.signalTextDim)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func requestNotifications() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    // MARK: Account chapter (Apple / Google)

    private var authChapter: some View {
        VStack(alignment: .leading, spacing: RinklerSpacing.lg) {
            VStack(alignment: .leading, spacing: RinklerSpacing.sm) {
                Text("Save your Focus System")
                    .font(RinklerFonts.sans(28, .bold))
                    .foregroundStyle(RinklerColors.signalText)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Make an account so your rules, streak, and Signal Score follow you across devices — and so a weak moment can't wipe them.")
                    .font(RinklerFonts.sans(15, .regular))
                    .foregroundStyle(RinklerColors.signalTextDim)
                    .fixedSize(horizontal: false, vertical: true)
            }

            savedSystemPreview

            VStack(spacing: 12) {
                SignInWithAppleButton(.continue) { request in
                    social.configureAppleRequest(request)
                } onCompletion: { result in
                    Task { if await social.handleApple(result) { onAuthSuccess() } }
                }
                .signInWithAppleButtonStyle(.white)
                .frame(height: 54)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .disabled(social.isLoading)

                Button {
                    Task { if await social.signInWithGoogle() { onAuthSuccess() } }
                } label: {
                    HStack(spacing: 10) {
                        GoogleGlyph()
                        Text("Continue with Google")
                            .font(RinklerFonts.sans(17, .semibold))
                            .foregroundStyle(.black)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(social.isLoading)

                if social.isLoading {
                    ProgressView()
                        .tint(RinklerColors.signalTextDim)
                        .padding(.top, 2)
                }

                if let error = social.errorMessage {
                    Text(error)
                        .font(RinklerFonts.sans(13, .regular))
                        .foregroundStyle(RinklerColors.signalWarning)
                        .fixedSize(horizontal: false, vertical: true)
                        .transition(.opacity)
                }
            }
            .opacity(authButtonsShown ? 1 : 0)
            .offset(y: authButtonsShown ? 0 : 18)
            .animation(.easeOut(duration: 0.2), value: social.errorMessage)
            .onAppear {
                authButtonsShown = false
                withAnimation(.easeOut(duration: 0.45).delay(0.12)) { authButtonsShown = true }
            }

            Text("Rinkler never posts on your behalf or reads your messages. Sign-in only secures your settings.")
                .font(RinklerFonts.sans(12, .regular))
                .foregroundStyle(RinklerColors.signalTextDim.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Compact card showing what the account will preserve.
    private var savedSystemPreview: some View {
        HStack(spacing: RinklerSpacing.md) {
            SignalRing(progress: Double(focusSystem.signalScore) / 100.0, lineWidth: 6) {
                Text("\(focusSystem.signalScore)")
                    .font(RinklerFonts.mono(18, .medium))
                    .foregroundStyle(RinklerColors.signalText)
            }
            .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 3) {
                Text("\(focusSystem.rules.count) rule\(focusSystem.rules.count == 1 ? "" : "s") ready to sync")
                    .font(RinklerFonts.sans(15, .semibold))
                    .foregroundStyle(RinklerColors.signalText)
                Text(focusSystem.rules.isEmpty
                     ? "Your Signal Score and streak"
                     : focusSystem.rules.map(\.name).joined(separator: " · "))
                    .font(RinklerFonts.sans(12, .regular))
                    .foregroundStyle(RinklerColors.signalTextDim)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(RinklerSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RinklerColors.signalCard)
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(RinklerColors.signalBorder, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    /// Records the freshly-stored session and advances to the final screen.
    private func onAuthSuccess() {
        authStore.refreshFromStoredSession()
        focusSystem.next()
    }

    // MARK: Footer CTA (one primary action per screen)

    @ViewBuilder private var footer: some View {
        VStack(spacing: 0) {
            if focusSystem.chapter == authChapterIndex {
                // Account is required — the only way forward is signing in with the
                // Apple/Google buttons above. No skip.
                EmptyView()
            } else {
                primaryButton(ctaTitle) { handlePrimary() }
            }
        }
        .padding(.horizontal, RinklerSpacing.lg)
    }

    private var ctaTitle: String {
        switch focusSystem.chapter {
        case 0: return "Let's go"
        case 6: return "Turn on the filter"
        case 7: return "Save my setup"
        case 8: return "Turn on notifications"
        case FocusSystemStore.chapterCount - 1: return "Start my first session"
        default: return "Continue"
        }
    }

    private func handlePrimary() {
        switch focusSystem.chapter {
        case 6:
            vpnManager.requestPermission()
            focusSystem.next()
        case 8:
            requestNotifications()
            focusSystem.next()
        case FocusSystemStore.chapterCount - 1:
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
                .foregroundStyle(RinklerColors.signalOnInk)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(RinklerColors.signalInk)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var rulesSummaryLine: String {
        let keeps = (focusSystem.keeps.isEmpty ? ["DMs", "Search"] : focusSystem.keeps.prefix(3).map(\.title))
        let cuts = (focusSystem.traps.isEmpty ? ["Reels", "TikTok FYP"] : focusSystem.traps.prefix(3).map(\.title))
        let n = focusSystem.rules.count
        if n == 0 {
            return "All clear. Add your own rules whenever."
        }
        return "Keeping \(keeps.joined(separator: ", ")) — cutting \(cuts.joined(separator: ", ")). That became \(n) rule\(n == 1 ? "" : "s")."
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
    @EnvironmentObject private var strictMode: StrictModeStore
    @EnvironmentObject private var sessions: FocusSessionStore

    var onSettings: (() -> Void)? = nil
    var onStartSession: (() -> Void)? = nil
    var onTrafficDashboard: (() -> Void)? = nil

    @State private var editingRule: FocusRule?

    var body: some View {
        ZStack {
            SignalBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: RinklerSpacing.lg) {
                    header
                    heroSection
                    statsCard
                    if !weekPoints.allSatisfy({ $0.value == 0 }) { weekCard }
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
        .preferredColorScheme(nil)
        .sheet(item: $editingRule) { rule in
            RuleEditorView(rule: rule)
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("TODAY")
                    .font(RinklerFonts.sans(13, .semibold))
                    .foregroundStyle(RinklerColors.signalTextDim)
                Text("Your setup")
                    .font(RinklerFonts.sans(24, .bold))
                    .foregroundStyle(RinklerColors.signalText)
            }
            Spacer()
            iconButton("chart.bar.fill", action: onTrafficDashboard)
            iconButton("line.3.horizontal", action: onSettings)
        }
    }

    private var heroSection: some View {
        VStack(spacing: RinklerSpacing.md) {
            ClaritySignal(streak: sessions.streak, size: 156)
                .padding(.top, RinklerSpacing.sm)
            VStack(spacing: 3) {
                Text(sessions.streak > 0 ? "\(sessions.streak)-day streak" : "You're all set")
                    .font(RinklerFonts.sans(20, .bold))
                    .foregroundStyle(RinklerColors.signalText)
                Text(sessions.streak > 0
                     ? "Keep it alive. Start a session and the ring sharpens."
                     : "Start a session and your signal starts to build.")
                    .font(RinklerFonts.sans(13, .regular))
                    .foregroundStyle(RinklerColors.signalTextDim)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var statsCard: some View {
        RinklerStatRow(stats: [
            ("Focused today", focusedLabel, nil),
            ("Pulls dodged", "\(sessions.todayDistractions)", RinklerColors.signalBlue),
            ("Streak", "\(sessions.streak)d", nil),
        ])
        .padding(.vertical, RinklerSpacing.md)
        .frame(maxWidth: .infinity)
        .signalCard(cornerRadius: 20)
    }

    private var weekCard: some View {
        VStack(alignment: .leading, spacing: RinklerSpacing.sm) {
            SectionHeader(title: "This week", subtitle: "Focused minutes per day")
            SignalChart(points: weekPoints)
        }
        .padding(RinklerSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .signalCard(cornerRadius: 20)
    }

    private var focusedLabel: String {
        let m = Int(sessions.todayFocusSeconds / 60)
        if m >= 60 { return "\(m / 60)h \(m % 60)m" }
        return "\(m)m"
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

    private var nextWindowCard: some View {
        Button { onStartSession?() } label: {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(nextRule != nil ? "Next window" : "Suggested")
                        .font(RinklerFonts.sans(12, .medium))
                        .foregroundStyle(RinklerColors.signalTextDim)
                    Text(nextRule?.name ?? "Quick 10-minute session")
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
            .signalCard(cornerRadius: 22)
        }
        .buttonStyle(.plain)
    }

    private var rulesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("RULES")
                    .font(RinklerFonts.sans(12, .semibold))
                    .foregroundStyle(RinklerColors.signalTextDim)
                Spacer()
                Button {
                    focusSystem.addBlankRule()
                    editingRule = focusSystem.rules.last
                } label: {
                    Label("Add", systemImage: "plus")
                        .font(RinklerFonts.sans(12, .semibold))
                        .foregroundStyle(RinklerColors.signalBlue)
                }
                .buttonStyle(.plain)
            }
            if focusSystem.rules.isEmpty {
                Text("No rules yet. Add one, or redo setup in Settings.")
                    .font(RinklerFonts.sans(13, .regular))
                    .foregroundStyle(RinklerColors.signalTextDim)
            } else {
                ForEach(focusSystem.rules) { rule in
                    Button { editingRule = rule } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(rule.name)
                                    .font(RinklerFonts.sans(16, .semibold))
                                    .foregroundStyle(rule.enabled ? RinklerColors.signalText : RinklerColors.signalTextDim)
                                if !rule.enabled {
                                    Text("Off")
                                        .font(RinklerFonts.sans(10, .medium))
                                        .foregroundStyle(RinklerColors.signalTextDim)
                                        .padding(.horizontal, 6).padding(.vertical, 2)
                                        .background(RinklerColors.signalCardRaised)
                                        .clipShape(Capsule())
                                }
                                Spacer()
                                Text(rule.difficulty.title)
                                    .font(RinklerFonts.sans(11, .medium))
                                    .foregroundStyle(RinklerColors.signalBlue)
                                    .padding(.horizontal, 8).padding(.vertical, 3)
                                    .background(RinklerColors.signalBlue.opacity(0.12))
                                    .clipShape(Capsule())
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(RinklerColors.signalTextDim)
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
                    .buttonStyle(.plain)
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
                    .foregroundStyle(vpnManager.vpnStatus == .connected ? RinklerColors.signalText : RinklerColors.signalOnInk)
                    .padding(.horizontal, 18).frame(height: 36)
                    .background(vpnManager.vpnStatus == .connected ? AnyView(RinklerColors.signalCardRaised) : AnyView(RinklerColors.signalInk))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(vpnManager.isPreparingProfile || strictMode.isActive)
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
