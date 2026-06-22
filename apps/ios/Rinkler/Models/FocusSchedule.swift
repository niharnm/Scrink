import Foundation
import Combine
import UserNotifications

// MARK: - Focus Schedule (Opal "Smart Schedules" parity)
//
// A recurring focus block: on the chosen weekdays at a set time, Rinkler reminds
// you (local notification) and — when you open from the reminder, or have the app
// open at that time — pre-fills and can auto-start the session. iOS does not let a
// third-party app silently launch a VPN in the background, so the honest model is
// "scheduled + one tap," not a true background auto-start.

struct FocusSchedule: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var label: String
    /// 1 = Sunday ... 7 = Saturday (matches Calendar weekday).
    var weekdays: Set<Int>
    var hour: Int
    var minute: Int
    var durationMinutes: Int          // 0 == open-ended
    var strictness: FocusStrictness
    var platforms: [FocusPlatform]
    var isEnabled: Bool = true

    var timeText: String {
        var c = DateComponents(); c.hour = hour; c.minute = minute
        let cal = Calendar.current
        if let date = cal.date(from: c) {
            let f = DateFormatter(); f.timeStyle = .short
            return f.string(from: date)
        }
        return String(format: "%02d:%02d", hour, minute)
    }

    var weekdaysText: String {
        if weekdays.count == 7 { return "Every day" }
        if weekdays == [2, 3, 4, 5, 6] { return "Weekdays" }
        if weekdays == [1, 7] { return "Weekends" }
        let symbols = Calendar.current.shortWeekdaySymbols   // ["Sun",...]
        return weekdays.sorted().compactMap { idx in
            (idx >= 1 && idx <= 7) ? symbols[idx - 1] : nil
        }.joined(separator: " ")
    }

    var durationText: String {
        if durationMinutes == 0 { return "Open" }
        if durationMinutes >= 60 {
            let h = durationMinutes / 60, m = durationMinutes % 60
            return m > 0 ? "\(h)h \(m)m" : "\(h)h"
        }
        return "\(durationMinutes)m"
    }
}

// MARK: - Store

@MainActor
final class ScheduleStore: ObservableObject {
    @Published private(set) var schedules: [FocusSchedule] = []

    private let defaults = UserDefaults.standard
    private let key = "rinkler.focusSchedules"

    init() { load() }

    // MARK: CRUD

    func add(_ schedule: FocusSchedule) {
        schedules.append(schedule)
        persist()
        refreshNotifications()
    }

    func update(_ schedule: FocusSchedule) {
        guard let i = schedules.firstIndex(where: { $0.id == schedule.id }) else { return }
        schedules[i] = schedule
        persist()
        refreshNotifications()
    }

    func delete(_ schedule: FocusSchedule) {
        schedules.removeAll { $0.id == schedule.id }
        persist()
        refreshNotifications()
    }

    func toggle(_ schedule: FocusSchedule) {
        guard let i = schedules.firstIndex(where: { $0.id == schedule.id }) else { return }
        schedules[i].isEnabled.toggle()
        persist()
        refreshNotifications()
    }

    /// The schedule whose time is "now" (within a small window) today, if any —
    /// used to offer a one-tap start when the app is open at the scheduled time.
    func dueNow(within minutes: Int = 10) -> FocusSchedule? {
        let cal = Calendar.current
        let now = Date()
        let weekday = cal.component(.weekday, from: now)
        return schedules.first { s in
            guard s.isEnabled, s.weekdays.contains(weekday) else { return false }
            var c = cal.dateComponents([.year, .month, .day], from: now)
            c.hour = s.hour; c.minute = s.minute
            guard let fire = cal.date(from: c) else { return false }
            let delta = now.timeIntervalSince(fire)
            return delta >= 0 && delta <= Double(minutes * 60)
        }
    }

    // MARK: Notifications

    func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    /// Rebuild all pending reminders from the current schedules.
    func refreshNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: pendingIdentifiers())
        for schedule in schedules where schedule.isEnabled {
            for weekday in schedule.weekdays {
                var comps = DateComponents()
                comps.weekday = weekday
                comps.hour = schedule.hour
                comps.minute = schedule.minute

                let content = UNMutableNotificationContent()
                content.title = "Time to focus"
                content.body = schedule.label.isEmpty
                    ? "Your scheduled focus block is starting. Tap to begin."
                    : "\(schedule.label) — tap to begin your focus block."
                content.sound = .default
                content.userInfo = ["scheduleID": schedule.id.uuidString]

                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
                let id = "\(schedule.id.uuidString)-\(weekday)"
                center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
            }
        }
    }

    private func pendingIdentifiers() -> [String] {
        schedules.flatMap { s in (1...7).map { "\(s.id.uuidString)-\($0)" } }
    }

    // MARK: Persistence

    private func persist() {
        if let data = try? JSONEncoder().encode(schedules) {
            defaults.set(data, forKey: key)
        }
    }

    private func load() {
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode([FocusSchedule].self, from: data) else { return }
        schedules = decoded
    }
}
