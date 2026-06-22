import Foundation

// MARK: - Block rule registry (the moat)
//
// Rinkler's value isn't the VPN — it's maintaining an accurate, versioned map of
// each app's *addictive* surfaces (Reels, Shorts, For You, Spotlight, Home feed)
// vs. its *useful* parts (DMs, search, profiles, notifications), and degrading
// gracefully when platforms move endpoints.
//
// Two enforcement tiers, both fed by this catalog:
//  • Feed-only (network host filter, best-effort, today): block the hosts that
//    serve a feature. Honest caveat: some features share hosts with useful parts,
//    so a host block can be broad. The precise version is the iOS 26 URL Filter
//    (per-URL), which this catalog also carries `urlPatterns` for.
//  • Whole-app (Family Controls Shield, reliable, entitlement-gated): the
//    fallback when feed-only is too broad or a platform breaks our rules.
//
// `version` lets a future remote registry ship rule-pack updates without an app
// release. The bundled copy below is the offline default.

struct BlockFeature: Identifiable, Codable, Hashable {
    let id: String          // "reels"
    let name: String        // "Reels"
    let blurb: String       // one-liner shown in the UI
    /// Hosts to block for the feed-only tier (suffix match).
    let hosts: [String]
    /// Full-URL patterns for the iOS 26 URL Filter (precise tier, future).
    let urlPatterns: [String]
    /// True when these hosts also carry useful parts (so feed-only is broad).
    let sharedHosts: Bool
}

struct BlockApp: Identifiable, Codable, Hashable {
    let id: String          // "instagram"
    let name: String        // "Instagram"
    let symbol: String      // SF Symbol fallback icon
    /// TikTok-style apps where the feed basically *is* the app.
    let mostlyFeed: Bool
    let features: [BlockFeature]
}

/// A versioned rule pack — the unit the remote registry (Supabase `block_rules`)
/// ships and the app caches, so endpoints can be updated without an App Store release.
struct RulePack: Codable {
    let version: String
    let apps: [BlockApp]
}

enum BlockCatalog {
    /// Bump when the bundled rules change; a remote pack can supersede this.
    static let version = "2026.06.22"
    /// App Group key holding the latest fetched RulePack (JSON).
    static let cacheKey = "blockRules.cachedPack"

    /// The rules in effect: the remotely-fetched pack if we have one, else the
    /// bundled default below. Lets `RuleRegistry` hot-update without a release.
    static var apps: [BlockApp] {
        if let data = UserDefaults(suiteName: RinklerConstants.appGroupID)?.data(forKey: cacheKey),
           let pack = try? JSONDecoder().decode(RulePack.self, from: data),
           !pack.apps.isEmpty {
            return pack.apps
        }
        return bundled
    }

    /// The offline default rule pack, shipped in the binary.
    static let bundled: [BlockApp] = [
        BlockApp(id: "instagram", name: "Instagram", symbol: "camera.fill", mostlyFeed: false, features: [
            BlockFeature(id: "reels", name: "Reels", blurb: "The short-video slot machine",
                         hosts: ["cdninstagram.com", "fbcdn.net", "fbvideo.net", "instagram.fbcdn.net"],
                         urlPatterns: ["instagram.com/reels/*", "i.instagram.com/api/*reels*", "i.instagram.com/api/*clips*"],
                         sharedHosts: true),
            BlockFeature(id: "explore", name: "Explore", blurb: "The discover grid",
                         hosts: [],
                         urlPatterns: ["instagram.com/explore/*", "i.instagram.com/api/*explore*", "i.instagram.com/api/*discover*"],
                         sharedHosts: true),
            BlockFeature(id: "feed", name: "Home feed", blurb: "The endless scroll",
                         hosts: [],
                         urlPatterns: ["i.instagram.com/api/*feed/timeline*"],
                         sharedHosts: true),
        ]),
        BlockApp(id: "tiktok", name: "TikTok", symbol: "music.note", mostlyFeed: true, features: [
            BlockFeature(id: "fyp", name: "For You feed", blurb: "Nearly the whole app is the feed",
                         hosts: ["tiktokv.com", "tiktokcdn.com", "tiktokcdn-us.com", "byteoversea.com", "muscdn.com", "ibytedtos.com", "byteimg.com"],
                         urlPatterns: ["*/api/recommend/item_list*", "*/aweme/v1/feed*"],
                         sharedHosts: true),
        ]),
        BlockApp(id: "youtube", name: "YouTube", symbol: "play.rectangle.fill", mostlyFeed: false, features: [
            BlockFeature(id: "shorts", name: "Shorts", blurb: "Vertical short video",
                         hosts: [],
                         urlPatterns: ["youtube.com/shorts/*", "youtubei.googleapis.com/*/reel/*", "youtubei.googleapis.com/*/shorts*"],
                         sharedHosts: true),
            BlockFeature(id: "home", name: "Home recommendations", blurb: "The recommended grid",
                         hosts: [],
                         urlPatterns: ["youtubei.googleapis.com/*/browse*"],
                         sharedHosts: true),
        ]),
        BlockApp(id: "snapchat", name: "Snapchat", symbol: "bolt.fill", mostlyFeed: false, features: [
            BlockFeature(id: "spotlight", name: "Spotlight", blurb: "Snap's short-video feed",
                         hosts: [],
                         urlPatterns: ["*/spotlight*", "*/discover/*"],
                         sharedHosts: true),
        ]),
        BlockApp(id: "reddit", name: "Reddit", symbol: "bubble.left.and.bubble.right.fill", mostlyFeed: false, features: [
            BlockFeature(id: "home", name: "Home / Popular feed", blurb: "The endless front page",
                         hosts: [],
                         urlPatterns: ["*/svc/shreddit/feeds/*", "oauth.reddit.com/*best*", "oauth.reddit.com/*popular*"],
                         sharedHosts: true),
        ]),
        BlockApp(id: "x", name: "X / Twitter", symbol: "bird.fill", mostlyFeed: false, features: [
            BlockFeature(id: "foryou", name: "For You timeline", blurb: "The algorithmic feed",
                         hosts: [],
                         urlPatterns: ["*/HomeTimeline*", "*/HomeLatestTimeline*"],
                         sharedHosts: true),
        ]),
        BlockApp(id: "facebook", name: "Facebook", symbol: "person.2.fill", mostlyFeed: false, features: [
            BlockFeature(id: "reels", name: "Reels & Watch", blurb: "Facebook's video feeds",
                         hosts: [],
                         urlPatterns: ["*/reels*", "*/watch*", "*/video/feed*"],
                         sharedHosts: true),
            BlockFeature(id: "feed", name: "News feed", blurb: "The home scroll",
                         hosts: [],
                         urlPatterns: ["*/feed*", "*/newsfeed*"],
                         sharedHosts: true),
        ]),
        BlockApp(id: "pinterest", name: "Pinterest", symbol: "pin.fill", mostlyFeed: true, features: [
            BlockFeature(id: "home", name: "Home feed", blurb: "The pin discovery feed",
                         hosts: ["pinimg.com"],
                         urlPatterns: ["*/v3/users/*/feed*", "*/v3/pidgets/*"],
                         sharedHosts: true),
        ]),
    ]

    static func app(_ id: String) -> BlockApp? { apps.first { $0.id == id } }

    /// Resolve a set of enabled "appId/featureId" keys → the host set to block.
    static func hosts(forEnabled enabled: Set<String>) -> [String] {
        var hosts: Set<String> = []
        for app in apps {
            for f in app.features where enabled.contains("\(app.id)/\(f.id)") {
                hosts.formUnion(f.hosts)
            }
        }
        return Array(hosts)
    }
}
