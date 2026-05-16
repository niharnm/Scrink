import Foundation
import Observation

@Observable
final class AppStore {
    var apps: [BlockedApp] = [
        BlockedApp(
            id: "instagram",
            name: "Instagram",
            iconName: "camera.fill",
            platform: "instagram",
            options: [
                BlockingOption(id: "reels", label: "short video", isEnabled: true)
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
        saveOptionState(appId: appId, optionId: optionId, isEnabled: apps[appIndex].options[optIndex].isEnabled)
    }

    private func loadOptionStates() {
        for appIndex in apps.indices {
            for optIndex in apps[appIndex].options.indices {
                if apps[appIndex].id == "instagram",
                   apps[appIndex].options[optIndex].id == "reels" {
                    apps[appIndex].options[optIndex].isEnabled = defaults?.object(forKey: BubbleConstants.blockReelsEnabledKey) as? Bool ?? true
                }
            }
        }
    }

    private func saveOptionState(appId: String, optionId: String, isEnabled: Bool) {
        if appId == "instagram", optionId == "reels" {
            defaults?.set(isEnabled, forKey: BubbleConstants.blockReelsEnabledKey)
        }
    }
}
