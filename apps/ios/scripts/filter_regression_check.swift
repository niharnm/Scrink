import Foundation

protocol ConnectionFilter {
    func shouldAllow(host: String, port: UInt16) -> FilterDecision
    func isStreamBlockTarget(_ domain: String) -> Bool
    func streamBlockThreshold(for sni: String) -> Int?
}

enum FilterDecision {
    case allow
    case block
}

@main
enum FilterRegressionCheck {
    static func main() throws {
        let suiteName = "com.rinkler.filter-regression.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            throw CheckError("Could not create isolated UserDefaults suite")
        }
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set(true, forKey: RinklerConstants.blockInstagramShortVideoEnabledKey)
        defaults.set(true, forKey: RinklerConstants.blockTikTokShortVideoEnabledKey)

        let thresholds = [
            "cdninstagram.com": 512,
            "tiktokcdn.com": 512,
            "googlevideo.com": 512,
            "youtube.com": 512,
            "youtubei.googleapis.com": 512,
        ]
        let thresholdData = try JSONEncoder().encode(thresholds)
        defaults.set(thresholdData, forKey: RinklerConstants.domainThresholdsKey)

        let filter = ReelsBlockFilter(sharedDefaults: defaults)

        try expect(
            filter.streamBlockThreshold(for: "scontent-lax3-2.cdninstagram.com") == 512,
            "Instagram CDN subdomains should be stream-thresholded"
        )
        try expect(
            filter.streamBlockThreshold(for: "v16-webapp-prime.tiktokcdn.com") == 512,
            "TikTok CDN subdomains should be stream-thresholded"
        )
        try expect(
            filter.streamBlockThreshold(for: "notcdninstagram.com") == nil,
            "Domain matching must not use loose substring matches"
        )
        try expect(
            filter.streamBlockThreshold(for: "rr3---sn-vgqsrn7z.googlevideo.com") == nil,
            "YouTube media hosts must not be blocked by stale saved thresholds"
        )
        try expect(
            filter.streamBlockThreshold(for: "www.youtube.com") == nil,
            "YouTube page hosts must not be stream-blocked as Shorts-only blocking"
        )
        try expect(
            filter.streamBlockThreshold(for: "youtubei.googleapis.com") == nil,
            "YouTube app API hosts must not be stream-blocked as Shorts-only blocking"
        )

        defaults.set(false, forKey: RinklerConstants.blockTikTokShortVideoEnabledKey)
        try expect(
            filter.streamBlockThreshold(for: "v16-webapp-prime.tiktokcdn.com") == nil,
            "TikTok threshold should respect the user toggle"
        )
        try expect(
            filter.streamBlockThreshold(for: "scontent-lax3-2.cdninstagram.com") == 512,
            "Instagram threshold should remain enabled when TikTok is off"
        )

        print("Filter regression checks passed")
    }

    private static func expect(_ condition: Bool, _ message: String) throws {
        if !condition {
            throw CheckError(message)
        }
    }
}

struct CheckError: Error, CustomStringConvertible {
    let description: String

    init(_ description: String) {
        self.description = description
    }
}
