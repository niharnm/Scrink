import SwiftUI
import Charts

struct TrafficDashboardView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var monitor = TrafficMonitor()

    var body: some View {
        ZStack {
            SkyBackgroundView()

            ScrollView {
                VStack(spacing: BubbleSpacing.md) {
                    // Section 1: Stats counters (tappable)
                    StatsCountersView(stats: monitor.current?.stats, events: monitor.events)

                    // Section 2: Top 5 Domains
                    TopDomainsChartView(domains: Array((monitor.current?.topDomains ?? []).prefix(5)))

                    // Section 3: Cumulative bytes timeline
                    BytesTimelineView(history: monitor.history)

                    // Section 4: Instant bytes timeline
                    InstantBytesView(history: monitor.history)

                    // Section 5: Active connections
                    ActiveConnectionsView(
                        connections: monitor.current?.connections ?? []
                    )
                }
                .padding(.horizontal, BubbleSpacing.lg)
                .padding(.top, BubbleSpacing.xl)
                .padding(.bottom, 100)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: { BackArrowView() }
            }
            ToolbarItem(placement: .principal) {
                Text("TRAFFIC")
                    .font(BubbleFonts.headerTitle)
                    .foregroundColor(.white)
            }
        }
        .onAppear { monitor.startPolling() }
        .onDisappear { monitor.stopPolling() }
    }
}

// MARK: - Stats Counters

private struct StatsCountersView: View {
    let stats: StatsSnapshot?
    let events: [TrafficEvent]

    var body: some View {
        HStack(spacing: 12) {
            NavigationLink {
                EventListView(title: "All Events", events: events, color: .primary)
            } label: {
                StatBox(label: "Total", value: stats?.totalConns ?? 0, color: .primary)
            }
            .buttonStyle(.plain)

            NavigationLink {
                EventListView(title: "Allowed", events: events.filter { $0.type == .allowed || $0.type == .completed }, color: .green)
            } label: {
                StatBox(label: "Allowed", value: stats?.tcpAllowed ?? 0, color: .green)
            }
            .buttonStyle(.plain)

            NavigationLink {
                EventListView(title: "Blocked", events: events.filter { $0.type == .blocked || $0.type == .streamBlocked }, color: .red)
            } label: {
                StatBox(label: "Blocked", value: stats?.tcpBlocked ?? 0, color: .red)
            }
            .buttonStyle(.plain)

            NavigationLink {
                EventListView(title: "Errors", events: events.filter { $0.type == .error }, color: .orange)
            } label: {
                StatBox(label: "Errors", value: stats?.errors ?? 0, color: .orange)
            }
            .buttonStyle(.plain)
        }
    }
}

private struct StatBox: View {
    let label: String
    let value: Int
    let color: Color

    var body: some View {
        VStack(spacing: BubbleSpacing.xs) {
            Text("\(value)")
                .font(BubbleFonts.pupok(size: 24))
                .foregroundColor(color)
            Text(label)
                .font(BubbleFonts.coolvetica(size: 12))
                .foregroundColor(BubbleColors.white60)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Event List

struct EventListView: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let events: [TrafficEvent]
    let color: Color

    var body: some View {
        ZStack {
            SkyBackgroundView()

            ScrollView {
                LazyVStack(spacing: BubbleSpacing.sm) {
                    ForEach(events.reversed()) { event in
                        VStack(alignment: .leading, spacing: BubbleSpacing.xs) {
                            HStack {
                                EventTypeBadge(type: event.type)
                                Spacer()
                                Text(event.timestamp, style: .time)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(BubbleColors.white60)
                            }

                            Text(event.sni ?? event.host)
                                .font(.system(size: 13, weight: .medium, design: .monospaced))
                                .foregroundColor(.white)
                                .lineLimit(1)

                            if event.host != event.sni ?? "" {
                                Text("\(event.host):\(event.port)")
                                    .font(.system(size: 11))
                                    .foregroundColor(BubbleColors.white60)
                            }

                            Text(event.detail)
                                .font(BubbleFonts.coolvetica(size: 12))
                                .foregroundColor(BubbleColors.white60)
                                .lineLimit(2)

                            if let bytes = event.bytesDown, bytes > 0 {
                                Text(formatBytes(bytes) + " down")
                                    .font(BubbleFonts.coolvetica(size: 12))
                                    .foregroundColor(BubbleColors.skyBlue)
                            }
                        }
                        .padding(BubbleSpacing.sm)
                        .background(Color.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(.horizontal, BubbleSpacing.lg)
                .padding(.top, BubbleSpacing.xl)
                .padding(.bottom, 100)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: { BackArrowView() }
            }
            ToolbarItem(placement: .principal) {
                Text(title.uppercased())
                    .font(BubbleFonts.headerTitle)
                    .foregroundColor(.white)
            }
        }
    }
}

private struct EventTypeBadge: View {
    let type: EventType

    private var label: String {
        switch type {
        case .allowed: return "ALLOWED"
        case .blocked: return "BLOCKED"
        case .streamBlocked: return "STREAM BLOCKED"
        case .error: return "ERROR"
        case .completed: return "COMPLETED"
        }
    }

    private var badgeColor: Color {
        switch type {
        case .allowed: return .green
        case .blocked: return .red
        case .streamBlocked: return .red
        case .error: return .orange
        case .completed: return .blue
        }
    }

    var body: some View {
        Text(label)
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(badgeColor)
            .cornerRadius(4)
    }
}

// MARK: - Top Domains Chart

private struct TopDomainsChartView: View {
    let domains: [DomainSnapshot]

    var body: some View {
        VStack(alignment: .leading, spacing: BubbleSpacing.sm) {
            Text("Top Domains")
                .font(BubbleFonts.pupok(size: 20))
                .foregroundColor(.white)

            if domains.isEmpty {
                Text("No data yet")
                    .font(BubbleFonts.coolvetica(size: 14))
                    .foregroundColor(BubbleColors.white60)
                    .frame(height: 150)
                    .frame(maxWidth: .infinity)
            } else {
                Chart(domains) { domain in
                    BarMark(
                        x: .value("Bytes", domain.totalBytes),
                        y: .value("Domain", shortDomain(domain.domain))
                    )
                    .foregroundStyle(BubbleColors.skyBlue)
                    .annotation(position: .trailing, alignment: .leading) {
                        Text("\(domain.count)x")
                            .font(BubbleFonts.coolvetica(size: 10))
                            .foregroundColor(BubbleColors.white60)
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let bytes = value.as(Int.self) {
                                Text(formatBytes(bytes))
                                    .font(.system(size: 9))
                                    .foregroundColor(BubbleColors.white60)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .foregroundStyle(Color.white)
                    }
                }
                .frame(height: CGFloat(max(domains.count, 1) * 36 + 30))
            }
        }
        .padding(BubbleSpacing.md)
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func shortDomain(_ domain: String) -> String {
        // Shorten "scontent-sjc6-1.cdninstagram.com" → "scontent-sjc6-1.cdn..."
        if domain.count > 25 {
            return String(domain.prefix(22)) + "..."
        }
        return domain
    }
}

// MARK: - Bytes Timeline

private struct BytesTimelineView: View {
    let history: [TrafficSnapshot]

    private var dataPoints: [(Date, Int)] {
        var cumulative = 0
        return history.map { snapshot in
            let snapshotBytes = snapshot.connections.reduce(0) { $0 + $1.bytesDown }
            cumulative += snapshotBytes
            return (snapshot.timestamp, cumulative)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: BubbleSpacing.sm) {
            Text("Cumulative Bytes Down")
                .font(BubbleFonts.pupok(size: 20))
                .foregroundColor(.white)

            if history.isEmpty {
                Text("No data yet")
                    .font(BubbleFonts.coolvetica(size: 14))
                    .foregroundColor(BubbleColors.white60)
                    .frame(height: 180)
                    .frame(maxWidth: .infinity)
            } else {
                Chart {
                    ForEach(Array(dataPoints.enumerated()), id: \.offset) { _, point in
                        LineMark(
                            x: .value("Time", point.0),
                            y: .value("Bytes", point.1)
                        )
                        .foregroundStyle(BubbleColors.skyBlue)

                        AreaMark(
                            x: .value("Time", point.0),
                            y: .value("Bytes", point.1)
                        )
                        .foregroundStyle(BubbleColors.skyBlue.opacity(0.15))
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let bytes = value.as(Int.self) {
                                Text(formatBytes(bytes))
                                    .font(.system(size: 9))
                                    .foregroundColor(BubbleColors.white60)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .foregroundStyle(BubbleColors.white60)
                    }
                }
                .frame(height: 180)
            }
        }
        .padding(BubbleSpacing.md)
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Instant Bytes

private struct InstantBytesView: View {
    let history: [TrafficSnapshot]

    private var dataPoints: [(Date, Int)] {
        guard history.count > 1 else { return [] }
        var points: [(Date, Int)] = []
        for i in 1..<history.count {
            let prev = history[i - 1]
            let curr = history[i]

            // Skip gaps > 2s (e.g. app was backgrounded)
            if curr.timestamp.timeIntervalSince(prev.timestamp) > 2.0 { continue }

            // Per-connection delta so appearing/disappearing connections don't skew
            let prevLookup = Dictionary(uniqueKeysWithValues: prev.connections.map { ($0.id, $0.bytesDown) })
            var delta = 0
            for conn in curr.connections {
                delta += max(conn.bytesDown - (prevLookup[conn.id] ?? 0), 0)
            }
            points.append((curr.timestamp, delta))
        }
        return points
    }

    var body: some View {
        VStack(alignment: .leading, spacing: BubbleSpacing.sm) {
            Text("Bytes Down (per snapshot)")
                .font(BubbleFonts.pupok(size: 20))
                .foregroundColor(.white)

            if history.isEmpty {
                Text("No data yet")
                    .font(BubbleFonts.coolvetica(size: 14))
                    .foregroundColor(BubbleColors.white60)
                    .frame(height: 180)
                    .frame(maxWidth: .infinity)
            } else {
                Chart {
                    ForEach(Array(dataPoints.enumerated()), id: \.offset) { _, point in
                        BarMark(
                            x: .value("Time", point.0),
                            y: .value("Bytes", point.1)
                        )
                        .foregroundStyle(Color.white.opacity(0.6))
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let bytes = value.as(Int.self) {
                                Text(formatBytes(bytes))
                                    .font(.system(size: 9))
                                    .foregroundColor(BubbleColors.white60)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .foregroundStyle(BubbleColors.white60)
                    }
                }
                .frame(height: 180)
            }
        }
        .padding(BubbleSpacing.md)
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Active Connections

private struct ActiveConnectionsView: View {
    let connections: [ConnectionSnapshot]

    private var activeConns: [ConnectionSnapshot] {
        connections.filter(\.isActive)
    }

    private var recentlyClosedConns: [ConnectionSnapshot] {
        connections.filter { !$0.isActive }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: BubbleSpacing.sm) {
            Text("Active Connections (\(activeConns.count))")
                .font(BubbleFonts.pupok(size: 20))
                .foregroundColor(.white)

            if activeConns.isEmpty && recentlyClosedConns.isEmpty {
                Text("No connections")
                    .font(BubbleFonts.coolvetica(size: 14))
                    .foregroundColor(BubbleColors.white60)
            }

            ForEach(activeConns) { conn in
                ConnectionRow(connection: conn)
            }

            if !recentlyClosedConns.isEmpty {
                Text("Recently Closed")
                    .font(BubbleFonts.coolvetica(size: 16))
                    .foregroundColor(BubbleColors.white60)
                    .padding(.top, BubbleSpacing.xs)

                ForEach(recentlyClosedConns) { conn in
                    ConnectionRow(connection: conn)
                        .opacity(0.5)
                }
            }
        }
        .padding(BubbleSpacing.md)
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct ConnectionRow: View {
    let connection: ConnectionSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(connection.sni ?? connection.host)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text("#\(connection.id) · \(connection.host):\(connection.port)")
                        .font(.system(size: 10))
                        .foregroundColor(BubbleColors.white60)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatBytes(connection.totalBytes))
                        .font(BubbleFonts.pupok(size: 14))
                        .foregroundColor(.white)
                    Text(durationString(from: connection.startTime))
                        .font(.system(size: 10))
                        .foregroundColor(BubbleColors.white60)
                }
            }

            // Bytes bar
            GeometryReader { geo in
                HStack(spacing: 1) {
                    let total = max(connection.totalBytes, 1)
                    Rectangle()
                        .fill(BubbleColors.skyBlue)
                        .frame(width: geo.size.width * CGFloat(connection.bytesUp) / CGFloat(total))
                    Rectangle()
                        .fill(Color.white.opacity(0.4))
                        .frame(width: geo.size.width * CGFloat(connection.bytesDown) / CGFloat(total))
                }
            }
            .frame(height: 4)
            .clipShape(RoundedRectangle(cornerRadius: 2))

            HStack {
                Label(formatBytes(connection.bytesUp), systemImage: "arrow.up")
                    .font(.system(size: 9))
                    .foregroundColor(BubbleColors.skyBlue)
                Spacer()
                Label(formatBytes(connection.bytesDown), systemImage: "arrow.down")
                    .font(.system(size: 9))
                    .foregroundColor(BubbleColors.white60)
            }
        }
        .padding(BubbleSpacing.sm)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(connection.isActive ? Color.white.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    private func durationString(from start: Date) -> String {
        let secs = Date().timeIntervalSince(start)
        if secs < 60 { return String(format: "%.0fs", secs) }
        return String(format: "%.0fm %.0fs", secs / 60, secs.truncatingRemainder(dividingBy: 60))
    }
}

// MARK: - Shared Helpers

private func formatBytes(_ bytes: Int) -> String {
    if bytes < 1024 { return "\(bytes) B" }
    let kb = Double(bytes) / 1024
    if kb < 1024 { return String(format: "%.1f KB", kb) }
    let mb = kb / 1024
    return String(format: "%.1f MB", mb)
}
