import Foundation
import Observation

struct AppOption: Codable, Identifiable {
    let id: String
    let label: String
    var isSelected: Bool
}

struct AppOptionsData: Codable {
    let appId: String
    let options: [AppOption]
}

struct AppOptionsResponse: Codable {
    let apps: [String: AppOptionsData]

    enum CodingKeys: String, CodingKey {
        case apps
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        apps = try container.decode([String: AppOptionsData].self, forKey: .apps)
    }
}

@Observable
final class AppOptionsService {
    static let shared = AppOptionsService()

    private var cachedData: [String: AppOptionsData] = [:]
    private var optionStateRevision = 0
    private let defaults = UserDefaults(suiteName: RinklerConstants.appGroupID)

    private init() {
        loadData()
    }

    func loadData() {
        guard let url = Bundle.main.url(forResource: "app_options", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([String: AppOptionsData].self, from: data) else {
            cachedData = Self.productionDefaults
            return
        }
        cachedData = decoded
    }

    func getOptions(for appId: String) -> AppOptionsData? {
        return cachedData[appId]
    }

    func getSelectedOptions(for appId: String) -> [AppOption] {
        return getAllOptions(for: appId).filter { $0.isSelected }
    }

    func getAllOptions(for appId: String) -> [AppOption] {
        _ = optionStateRevision
        guard let appData = cachedData[appId] else { return [] }
        return appData.options.map { option in
            var mutableOption = option
            mutableOption.isSelected = isOptionSelected(appId: appId, optionId: option.id)
            return mutableOption
        }
    }

    func toggleOption(appId: String, optionId: String) {
        guard let key = defaultsKey(appId: appId, optionId: optionId) else { return }
        defaults?.set(!isOptionSelected(appId: appId, optionId: optionId), forKey: key)
        optionStateRevision += 1
    }

    func isOptionSelected(appId: String, optionId: String) -> Bool {
        guard let key = defaultsKey(appId: appId, optionId: optionId) else { return false }
        return defaults?.object(forKey: key) as? Bool ?? true
    }

    private static let productionDefaults: [String: AppOptionsData] = [
        "instagram": AppOptionsData(
            appId: "instagram",
            options: [
                AppOption(id: "reels", label: "short video", isSelected: true)
            ]
        ),
        "tiktok": AppOptionsData(
            appId: "tiktok",
            options: [
                AppOption(id: "scroll", label: "scroll feed", isSelected: true)
            ]
        )
    ]

    private func defaultsKey(appId: String, optionId: String) -> String? {
        switch (appId, optionId) {
        case ("instagram", "reels"):
            return RinklerConstants.blockInstagramShortVideoEnabledKey
        case ("tiktok", "scroll"):
            return RinklerConstants.blockTikTokShortVideoEnabledKey
        default:
            return nil
        }
    }
}
