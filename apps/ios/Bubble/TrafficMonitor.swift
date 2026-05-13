import Foundation
import Combine

@MainActor
final class TrafficMonitor: ObservableObject {
    @Published var current: TrafficSnapshot?
    @Published var history: [TrafficSnapshot] = []
    @Published var events: [TrafficEvent] = []

    private var timer: AnyCancellable?
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private let statsFileURL: URL? = {
        FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: BubbleConstants.appGroupID
        )?.appendingPathComponent(BubbleConstants.statsFileName)
    }()

    func startPolling() {
        timer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refresh()
            }
    }

    func stopPolling() {
        timer?.cancel()
        timer = nil
    }

    func clearHistory() {
        history.removeAll()
        events.removeAll()
        current = nil
    }

    // Cumulative bytes down from history
    var cumulativeBytesDown: Int {
        history.reduce(0) { total, snapshot in
            total + snapshot.connections.reduce(0) { $0 + $1.bytesDown }
        }
    }

    func events(ofType type: EventType) -> [TrafficEvent] {
        events.filter { $0.type == type }
    }

    private func refresh() {
        guard let url = statsFileURL,
              let data = try? Data(contentsOf: url) else {
            return
        }

        if let trafficData = try? decoder.decode(TrafficData.self, from: data) {
            if !trafficData.snapshots.isEmpty {
                history = trafficData.snapshots
                current = trafficData.snapshots.last
            }
            events = trafficData.events
        }
    }
}
