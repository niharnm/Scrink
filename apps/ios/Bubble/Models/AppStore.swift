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
        ),
        BlockedApp(
            id: "tiktok",
            name: "TikTok",
            iconName: "music.note",
            platform: "tiktok",
            options: [
                BlockingOption(id: "scroll", label: "scroll feed", isEnabled: true)
            ]
        ),
        BlockedApp(
            id: "youtube",
            name: "YouTube",
            iconName: "play.rectangle.fill",
            platform: "youtube",
            options: [
                BlockingOption(id: "video", label: "video streams", isEnabled: true)
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
                if let key = defaultsKey(appId: apps[appIndex].id, optionId: apps[appIndex].options[optIndex].id) {
                    apps[appIndex].options[optIndex].isEnabled = defaults?.object(forKey: key) as? Bool ?? true
                }
            }
        }
    }

    private func saveOptionState(appId: String, optionId: String, isEnabled: Bool) {
        if let key = defaultsKey(appId: appId, optionId: optionId) {
            defaults?.set(isEnabled, forKey: key)
        }
    }

    private func defaultsKey(appId: String, optionId: String) -> String? {
        switch (appId, optionId) {
        case ("instagram", "reels"):
            return BubbleConstants.blockInstagramShortVideoEnabledKey
        case ("tiktok", "scroll"):
            return BubbleConstants.blockTikTokShortVideoEnabledKey
        case ("youtube", "video"):
            return BubbleConstants.blockYouTubeShortVideoEnabledKey
        default:
            return nil
        }
    }
}
