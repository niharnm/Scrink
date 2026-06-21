import Foundation

/// A single scheduled blocking window, written by the app (from the user's
/// generated Focus System rules) into the shared App Group. Times are minutes
/// from midnight; `ig`/`tt` say which apps the window blocks; `th` is the byte
/// threshold to apply while it is active (0 = block immediately).
struct ScheduleWindow: Codable {
    let start: Int
    let end: Int
    let ig: Bool
    let tt: Bool
    let th: Int

    /// Whether `minute` (minutes from midnight) falls inside this window,
    /// handling windows that wrap past midnight (e.g. 22:30 → 07:00).
    func covers(minute: Int) -> Bool {
        if start <= end { return minute >= start && minute < end }
        return minute >= start || minute < end
    }
}

/// Reads the app-written schedule from the shared App Group and answers "is a
/// blocking window active right now for this app?". The tunnel owns evaluation
/// so schedules hold whenever the VPN is up — no need for the app to be open.
final class ScheduleStore {
    private let defaults = UserDefaults(suiteName: RinklerConstants.appGroupID)
    private let key = RinklerConstants.ruleScheduleKey

    private func windows() -> [ScheduleWindow] {
        guard let data = defaults?.data(forKey: key),
              let list = try? JSONDecoder().decode([ScheduleWindow].self, from: data) else { return [] }
        return list
    }

    private func nowMinute() -> Int {
        let c = Calendar.current.dateComponents([.hour, .minute], from: Date())
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }

    /// The active window blocking the given app right now, if any.
    func activeWindow(ig: Bool, tt: Bool) -> ScheduleWindow? {
        let m = nowMinute()
        return windows().first { w in
            w.covers(minute: m) && ((ig && w.ig) || (tt && w.tt))
        }
    }

    /// Whether any window is currently blocking something.
    var anyActive: Bool {
        let m = nowMinute()
        return windows().contains { $0.covers(minute: m) && ($0.ig || $0.tt) }
    }
}
