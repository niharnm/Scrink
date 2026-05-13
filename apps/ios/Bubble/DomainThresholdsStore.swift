import SwiftUI

// MARK: - Domain Thresholds Store

class DomainThresholdsStore: ObservableObject {
    @Published var thresholds: [String: Int] = [:]

    private let defaults = UserDefaults(suiteName: BubbleConstants.appGroupID)

    init() { load() }

    func load() {
        guard let data = defaults?.data(forKey: BubbleConstants.domainThresholdsKey),
              let dict = try? JSONDecoder().decode([String: Int].self, from: data) else {
            thresholds = [:]
            return
        }
        thresholds = dict
    }

    func save() {
        guard let data = try? JSONEncoder().encode(thresholds) else { return }
        defaults?.set(data, forKey: BubbleConstants.domainThresholdsKey)
    }

    func binding(for domain: String) -> Binding<Int> {
        Binding(
            get: { self.thresholds[domain] ?? BubbleConstants.noLimitThreshold },
            set: { newValue in
                self.thresholds[domain] = newValue
                self.save()
            }
        )
    }
}

// MARK: - Per-Domain Slider Row

struct DomainThresholdRow: View {
    let domain: String
    @Binding var threshold: Int

    private let maxSliderValue: Double = 5_242_880 + 10_240 // 5 MB + one step = "No limit"

    var body: some View {
        VStack(spacing: 2) {
            HStack {
                Text(domain)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer()
                Text(thresholdLabel)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(threshold == BubbleConstants.noLimitThreshold ? .green : (threshold == 0 ? .red : .orange))
            }
            Slider(
                value: Binding(
                    get: { threshold == BubbleConstants.noLimitThreshold ? maxSliderValue : Double(threshold) },
                    set: { newVal in
                        if newVal >= 5_242_880 + 5_120 {
                            threshold = BubbleConstants.noLimitThreshold
                        } else {
                            threshold = Int(newVal)
                        }
                    }
                ),
                in: 0...maxSliderValue,
                step: 10_240
            )
        }
    }

    private var thresholdLabel: String {
        if threshold == BubbleConstants.noLimitThreshold { return "No limit" }
        if threshold == 0 { return "BLOCK ALL" }
        if threshold < 1_048_576 {
            return String(format: "%.0f KB", Double(threshold) / 1024)
        }
        return String(format: "%.1f MB", Double(threshold) / 1_048_576)
    }
}
