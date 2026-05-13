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
    private var optionStates: [String: [String: Bool]] = [:] // appId -> optionId -> isSelected
    private let defaults = UserDefaults(suiteName: BubbleConstants.appGroupID)

    private init() {
        loadData()
        loadSavedStates()
    }

    func loadData() {
        guard let url = Bundle.main.url(forResource: "app_options", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([String: AppOptionsData].self, from: data) else {
            return
        }
        cachedData = decoded

        // Initialize option states from cached data (all default to false from JSON)
        for (appId, appData) in decoded {
            var states: [String: Bool] = [:]
            for option in appData.options {
                states[option.id] = option.isSelected
            }
            optionStates[appId] = states
        }
    }

    private func loadSavedStates() {
        guard let data = defaults?.data(forKey: BubbleConstants.optionStatesKey),
              let saved = try? JSONDecoder().decode([String: [String: Bool]].self, from: data) else { return }

        for (appId, appStates) in saved {
            if optionStates[appId] == nil {
                optionStates[appId] = [:]
            }
            for (optionId, isSelected) in appStates {
                optionStates[appId]?[optionId] = isSelected
            }
        }
    }

    private func saveStates() {
        if let data = try? JSONEncoder().encode(optionStates) {
            defaults?.set(data, forKey: BubbleConstants.optionStatesKey)
        }
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
            mutableOption.isSelected = optionStates[appId]?[option.id] ?? false
            return mutableOption
        }
    }

    func toggleOption(appId: String, optionId: String) {
        if optionStates[appId] == nil {
            optionStates[appId] = [:]
        }
        let currentState = optionStates[appId]?[optionId] ?? false
        optionStates[appId]?[optionId] = !currentState
        saveStates()
    }

    func isOptionSelected(appId: String, optionId: String) -> Bool {
        return optionStates[appId]?[optionId] ?? false
    }
}
