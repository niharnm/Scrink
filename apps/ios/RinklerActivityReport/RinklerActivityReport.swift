import DeviceActivity
import SwiftUI

// DeviceActivity Report extension — the ONLY way to surface real per-app screen
// time (the system computes it in this sandboxed extension; the app can't read
// raw usage directly). The app hosts it via DeviceActivityReport(.rinklerUsage,…).

extension DeviceActivityReport.Context {
    static let rinklerUsage = Self(rawValue: "rinklerUsage")
}

struct UsageModel {
    var total: TimeInterval = 0
    var apps: [AppRow] = []
}

struct AppRow: Identifiable {
    let id: String
    let name: String
    let seconds: TimeInterval
}

@main
struct RinklerActivityReport: DeviceActivityReportExtension {
    var body: some DeviceActivityReportScene {
        UsageScene { model in UsageReportContentView(model: model) }
    }
}

struct UsageScene: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .rinklerUsage
    let content: (UsageModel) -> UsageReportContentView

    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> UsageModel {
        var total: TimeInterval = 0
        var byApp: [String: (name: String, seconds: TimeInterval)] = [:]

        for await each in data {
            for await segment in each.activitySegments {
                total += segment.totalActivityDuration
                for await category in segment.categories {
                    for await app in category.applications {
                        let key = app.application.bundleIdentifier
                            ?? app.application.localizedDisplayName
                            ?? UUID().uuidString
                        let name = app.application.localizedDisplayName ?? "App"
                        byApp[key, default: (name, 0)].seconds += app.totalActivityDuration
                    }
                }
            }
        }

        let rows = byApp
            .map { AppRow(id: $0.key, name: $0.value.name, seconds: $0.value.seconds) }
            .sorted { $0.seconds > $1.seconds }
        return UsageModel(total: total, apps: Array(rows.prefix(6)))
    }
}

/// Rendered inside the app's report view. Self-contained styling (the extension
/// is a separate target without the app's theme files) but matched to the stark
/// black + blue look.
struct UsageReportContentView: View {
    let model: UsageModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SCREEN TIME TODAY")
                .font(.system(size: 11, weight: .semibold)).tracking(1)
                .foregroundStyle(Color.white.opacity(0.5))
            Text(Self.label(model.total))
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            if model.apps.isEmpty {
                Text("No usage recorded yet today.")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.white.opacity(0.5))
            } else {
                ForEach(model.apps) { app in
                    HStack {
                        Text(app.name)
                            .font(.system(size: 14))
                            .foregroundStyle(Color.white.opacity(0.9))
                            .lineLimit(1)
                        Spacer(minLength: 8)
                        Text(Self.label(app.seconds))
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundStyle(Color(red: 0.43, green: 0.55, blue: 1.0))
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    static func label(_ s: TimeInterval) -> String {
        let m = Int(s / 60)
        if m >= 60 { return "\(m / 60)h \(m % 60)m" }
        return "\(m)m"
    }
}
