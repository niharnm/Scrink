import Foundation

// MARK: - Story Mode
//
// Rinkler's identity is a night sky that clears toward dawn as you focus.
// Story Mode makes that metaphor explicit and gives long-term meaning to focus
// sessions:
//
//   • Intro  — a one-time, cinematic onboarding that explains *why* the feeds
//              pull at you and how Rinkler removes the feed without removing the
//              app. The sky literally clears as the user advances.
//   • Journey — an ongoing progression. Cumulative focus unlocks "chapters"
//              (First Light -> Clear Sky). Each chapter raises the sky's
//              permanent clarity, so the app's whole mood reflects the user's
//              real history, not a cosmetic badge.
//
// Every threshold is measured against REAL data already tracked by
// FocusSessionStore (wall-clock protected minutes, completed sessions, streak,
// distractions interrupted). Nothing here is fabricated.

/// One stage of the long-term "restore the sky" journey.
struct StoryChapter: Identifiable, Equatable {
    enum Goal: Equatable {
        case firstSession
        case protectedMinutes(Int)
        case sessions(Int)
        case streakDays(Int)

        /// How far `progress` is toward the goal, 0...1.
        func fraction(_ p: StoryProgress) -> Double {
            switch self {
            case .firstSession:
                return p.lifetimeSessions >= 1 ? 1 : 0
            case .protectedMinutes(let target):
                return min(1, Double(p.lifetimeProtectedMinutes) / Double(max(1, target)))
            case .sessions(let target):
                return min(1, Double(p.lifetimeSessions) / Double(max(1, target)))
            case .streakDays(let target):
                return min(1, Double(p.bestStreak) / Double(max(1, target)))
            }
        }

        var requirementText: String {
            switch self {
            case .firstSession: return "Complete your first focus session"
            case .protectedMinutes(let m):
                return m >= 60 ? "Protect \(m / 60)h of focus" : "Protect \(m) min of focus"
            case .sessions(let s): return "Finish \(s) focus sessions"
            case .streakDays(let d): return "Reach a \(d)-day streak"
            }
        }
    }

    let id: Int
    let title: String
    /// The line revealed when this chapter unlocks — the narrative beat.
    let narrative: String
    let goal: Goal
    /// The sky clarity (0...1) this chapter settles the world into once reached.
    let clarity: Double

    func isUnlocked(_ p: StoryProgress) -> Bool { goal.fraction(p) >= 1 }
}

/// A flat snapshot of the lifetime numbers the journey is scored against.
struct StoryProgress: Equatable {
    var lifetimeSessions: Int
    var lifetimeProtectedMinutes: Int
    var lifetimeDistractions: Int
    var bestStreak: Int

    static let empty = StoryProgress(lifetimeSessions: 0, lifetimeProtectedMinutes: 0,
                                     lifetimeDistractions: 0, bestStreak: 0)
}

enum Story {
    /// The chapter ladder — night to dawn. Ordered by ascending difficulty.
    static let chapters: [StoryChapter] = [
        StoryChapter(
            id: 0, title: "First Light",
            narrative: "You held the line once. In a sky this dark, one spark is the whole beginning.",
            goal: .firstSession, clarity: 0.30
        ),
        StoryChapter(
            id: 1, title: "The Haze Lifts",
            narrative: "An hour you'd have lost to the scroll is yours. The fog over the horizon starts to thin.",
            goal: .protectedMinutes(60), clarity: 0.42
        ),
        StoryChapter(
            id: 2, title: "Breaking Cloud",
            narrative: "Five sessions in. This isn't a fluke anymore — it's a habit pushing the clouds apart.",
            goal: .sessions(5), clarity: 0.55
        ),
        StoryChapter(
            id: 3, title: "Horizon",
            narrative: "Five hours reclaimed. The first warm band of dawn shows at the edge of the world.",
            goal: .protectedMinutes(300), clarity: 0.68
        ),
        StoryChapter(
            id: 4, title: "Aurora",
            narrative: "A week unbroken. The sky answers with light it only gives to the consistent.",
            goal: .streakDays(7), clarity: 0.80
        ),
        StoryChapter(
            id: 5, title: "Daybreak",
            narrative: "Twenty hours of focus protected. The night is the exception now, not the rule.",
            goal: .protectedMinutes(1200), clarity: 0.90
        ),
        StoryChapter(
            id: 6, title: "Clear Sky",
            narrative: "Fifty hours. The feeds are still out there — they just don't run your days anymore.",
            goal: .protectedMinutes(3000), clarity: 1.0
        ),
    ]

    /// The highest chapter the user has unlocked, if any.
    static func currentChapter(_ p: StoryProgress) -> StoryChapter? {
        chapters.last { $0.isUnlocked(p) }
    }

    /// The next chapter still to earn, if any remain.
    static func nextChapter(_ p: StoryProgress) -> StoryChapter? {
        chapters.first { !$0.isUnlocked(p) }
    }

    /// Earned clarity from journey progress — a permanent floor the home/journey
    /// sky settles into, separate from the live session boost.
    static func earnedClarity(_ p: StoryProgress) -> Double {
        currentChapter(p)?.clarity ?? 0.18
    }

    // MARK: First-run flag

    private static let seenIntroKey = "rinkler.story.hasSeenIntro"

    static var hasSeenIntro: Bool {
        get { UserDefaults.standard.bool(forKey: seenIntroKey) }
        set { UserDefaults.standard.set(newValue, forKey: seenIntroKey) }
    }
}

// MARK: - Lifetime totals for the journey

extension FocusSessionStore {
    /// Total minutes ever protected (completed sessions + any live session).
    var lifetimeProtectedMinutes: Int {
        var seconds = records.reduce(0.0) { $0 + $1.durationSeconds }
        if let active { seconds += Date().timeIntervalSince(active.startedAt) }
        return Int(seconds / 60)
    }

    /// Total completed sessions ever (a running session counts toward "now").
    var lifetimeSessions: Int { records.count + (isRunning ? 1 : 0) }

    /// Total distracting streams ever interrupted.
    var lifetimeDistractions: Int {
        records.reduce(0) { $0 + $1.distractionsInterrupted } + (isRunning ? liveDistractions : 0)
    }

    /// The longest run of consecutive days that contained at least one session.
    var bestStreak: Int {
        let cal = Calendar.current
        let days = records.map { cal.startOfDay(for: $0.startedAt) }
        let unique = Set(days).sorted()
        guard !unique.isEmpty else { return isRunning ? 1 : 0 }
        var best = 1
        var run = 1
        for i in 1..<max(1, unique.count) {
            if let prevPlusOne = cal.date(byAdding: .day, value: 1, to: unique[i - 1]),
               cal.isDate(prevPlusOne, inSameDayAs: unique[i]) {
                run += 1
            } else {
                run = 1
            }
            best = max(best, run)
        }
        return max(best, streak)
    }

    /// Snapshot scored by Story Mode.
    var storyProgress: StoryProgress {
        StoryProgress(
            lifetimeSessions: lifetimeSessions,
            lifetimeProtectedMinutes: lifetimeProtectedMinutes,
            lifetimeDistractions: lifetimeDistractions,
            bestStreak: bestStreak
        )
    }

    /// Clarity that blends earned journey progress with the live session boost,
    /// so the home sky reflects both who you've become and what you're doing now.
    var storyClarity: Double {
        let earned = Story.earnedClarity(storyProgress)
        let live = isRunning ? 0.2 : 0.0
        return min(1.0, earned + live)
    }
}
