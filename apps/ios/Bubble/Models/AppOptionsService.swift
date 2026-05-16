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
    private var reelFilterEnabled: Bool
    private let defaults = UserDefaults(suiteName: BubbleConstants.appGroupID)

    private init() {
        self.reelFilterEnabled = defaults?.object(forKey: BubbleConstants.blockReelsEnabledKey) as? Bool ?? true
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
        guard let appData = cachedData[appId] else { return [] }
        return appData.options.map { option in
            var mutableOption = option
            mutableOption.isSelected = isOptionSelected(appId: appId, optionId: option.id)
            return mutableOption
        }
    }

    func toggleOption(appId: String, optionId: String) {
        guard appId == "instagram", optionId == "reels" else { return }
        reelFilterEnabled.toggle()
        defaults?.set(reelFilterEnabled, forKey: BubbleConstants.blockReelsEnabledKey)
    }

    func isOptionSelected(appId: String, optionId: String) -> Bool {
        guard appId == "instagram", optionId == "reels" else { return false }
        return reelFilterEnabled
    }

    private static let productionDefaults: [String: AppOptionsData] = [
        "instagram": AppOptionsData(
            appId: "instagram",
            options: [
                AppOption(id: "reels", label: "short video", isSelected: true)
            ]
        )
    ]
}
