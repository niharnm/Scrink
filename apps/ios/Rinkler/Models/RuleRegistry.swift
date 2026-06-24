import Foundation

/// Pulls the active remote rule pack from Supabase (`block_rules`) and caches it
/// so `BlockCatalog` can hot-update each app's addictive-feed endpoints without
/// an App Store release (platforms move hosts constantly). Read-only with the
/// public anon key; falls back silently to the bundled catalog on any failure.
enum RuleRegistry {
    private struct Row: Decodable {
        let version: String
        let pack: RulePack
    }

    static func sync() async {
        guard let info = Bundle.main.infoDictionary,
              let urlStr = info["SUPABASE_URL"] as? String,
              let key = info["SUPABASE_KEY"] as? String,
              !urlStr.isEmpty, !key.isEmpty,
              let base = URL(string: urlStr),
              var comps = URLComponents(url: base, resolvingAgainstBaseURL: false) else { return }

        comps.path = "/rest/v1/block_rules"
        comps.queryItems = [
            URLQueryItem(name: "select", value: "version,pack"),
            URLQueryItem(name: "is_active", value: "eq.true"),
            URLQueryItem(name: "limit", value: "1"),
        ]
        guard let url = comps.url else { return }

        var req = URLRequest(url: url)
        req.setValue(key, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")

        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else { return }
            let rows = try JSONDecoder().decode([Row].self, from: data)
            guard let row = rows.first, !row.pack.apps.isEmpty else { return }
            if let encoded = try? JSONEncoder().encode(row.pack) {
                UserDefaults(suiteName: RinklerConstants.appGroupID)?.set(encoded, forKey: BlockCatalog.cacheKey)
            }
        } catch {
            // Network/decoding failure → keep whatever's cached / bundled.
        }
    }
}
