import Foundation
import Observation

@Observable
final class AppStore {
    var apps: [BlockedApp] = [
        BlockedApp(
            id: "instagram",
            name: "INSTAGRAM",
            iconName: "camera.fill",
            platform: "instagram",
            options: [
                BlockingOption(id: "reels", label: "reels", isEnabled: false),
                BlockingOption(id: "msgs", label: "msgs", isEnabled: false),
                BlockingOption(id: "profiles", label: "profiles", isEnabled: false),
                BlockingOption(id: "explore", label: "explore", isEnabled: false)
            ]
        ),
        BlockedApp(
            id: "shield",
            name: "SHIELD",
            iconName: "shield.fill",
            platform: "facebook",
            options: [
                BlockingOption(id: "alerts", label: "alerts", isEnabled: false),
                BlockingOption(id: "feeds", label: "feeds", isEnabled: false)
            ]
        ),
        BlockedApp(
            id: "kalshi",
            name: "KALSHI",
            iconName: "chart.bar.fill",
            platform: "kalshi",
            options: [
                BlockingOption(id: "trades", label: "trades", isEnabled: false),
                BlockingOption(id: "notifs", label: "notifs", isEnabled: false)
            ]
        ),
        BlockedApp(
            id: "fanduel",
            name: "FANDUEL",
            iconName: "sportscourt.fill",
            platform: "fanduel",
            options: [
                BlockingOption(id: "bets", label: "bets", isEnabled: false),
                BlockingOption(id: "notifs", label: "notifs", isEnabled: false)
            ]
        )
    ]

    private let defaults = UserDefaults(suiteName: BubbleConstants.appGroupID)

    init() {
        loadOptionStates()
    }

    func app(for id: String) -> BlockedApp? {
        apps.first { $0.id == id }
    }

    func toggleOption(appId: String, optionId: String) {
        guard let appIndex = apps.firstIndex(where: { $0.id == appId }),
              let optIndex = apps[appIndex].options.firstIndex(where: { $0.id == optionId }) else { return }
        apps[appIndex].options[optIndex].isEnabled.toggle()
        saveOptionStates()
    }

    private func loadOptionStates() {
        guard let data = defaults?.data(forKey: BubbleConstants.optionStatesKey),
              let saved = try? JSONDecoder().decode([String: [String: Bool]].self, from: data) else { return }

        for appIndex in apps.indices {
            let appId = apps[appIndex].id
            guard let appStates = saved[appId] else { continue }
            for optIndex in apps[appIndex].options.indices {
                let optId = apps[appIndex].options[optIndex].id
                if let isEnabled = appStates[optId] {
                    apps[appIndex].options[optIndex].isEnabled = isEnabled
                }
            }
        }
    }

    private func saveOptionStates() {
        var states: [String: [String: Bool]] = [:]
        for app in apps {
            var appStates: [String: Bool] = [:]
            for option in app.options {
                appStates[option.id] = option.isEnabled
            }
            states[app.id] = appStates
        }
        if let data = try? JSONEncoder().encode(states) {
            defaults?.set(data, forKey: BubbleConstants.optionStatesKey)
        }
    }
}
