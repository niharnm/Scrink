import SwiftUI
import Charts

// MARK: - Shared building blocks
//
// One small kit so every screen is built from the same parts instead of
// one-off stacks. Premium structure (à la Opal) in Rinkler's stark skin:
// true-black, hairline borders, one blue accent, mono numbers, no glow.

/// Tiny uppercase label over a big value — the unit of every stat row.
struct StatBlock: View {
    let label: String
    let value: String
    var accent: Color? = nil

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(RinklerFonts.mono(22, .medium))
                .foregroundStyle(accent ?? RinklerColors.signalText)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label.uppercased())
                .font(RinklerFonts.sans(10, .semibold))
                .tracking(1)
                .foregroundStyle(RinklerColors.signalTextDim)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

/// A row of StatBlocks split by hairlines (FOCUS · TIME BACK · STREAK).
struct RinklerStatRow: View {
    let stats: [(label: String, value: String, accent: Color?)]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(stats.enumerated()), id: \.offset) { i, s in
                if i > 0 {
                    Rectangle().fill(RinklerColors.signalBorder).frame(width: 1, height: 30)
                }
                StatBlock(label: s.label, value: s.value, accent: s.accent)
            }
        }
    }
}

/// Bold title + dim subtitle, left aligned.
struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(RinklerFonts.sans(20, .bold))
                .foregroundStyle(RinklerColors.signalText)
            if let subtitle {
                Text(subtitle)
                    .font(RinklerFonts.sans(13, .regular))
                    .foregroundStyle(RinklerColors.signalTextDim)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A small status chip (✓ done, timer, disabled).
struct StatusPill: View {
    let text: String
    var icon: String? = nil
    var tone: Color = RinklerColors.signalTextDim

    var body: some View {
        HStack(spacing: 4) {
            if let icon { Image(systemName: icon).font(.system(size: 10, weight: .bold)) }
            Text(text).font(RinklerFonts.sans(11, .semibold))
        }
        .foregroundStyle(tone)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(tone.opacity(0.14))
        .clipShape(Capsule())
    }
}

/// Generic segmented control (Week/Month/Lifetime, etc.) in our pill style.
struct RinklerSegmented<T: Hashable>: View {
    let items: [(label: String, value: T)]
    @Binding var selection: T

    var body: some View {
        HStack(spacing: 4) {
            ForEach(items, id: \.value) { item in
                Button { withAnimation(.snappy) { selection = item.value } } label: {
                    Text(item.label)
                        .font(RinklerFonts.sans(13, .semibold))
                        .foregroundStyle(selection == item.value ? RinklerColors.signalOnInk : RinklerColors.signalTextDim)
                        .frame(maxWidth: .infinity)
                        .frame(height: 34)
                        .background(selection == item.value ? AnyView(RinklerColors.signalInk) : AnyView(Color.clear))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(RinklerColors.signalCard)
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(RinklerColors.signalBorder, lineWidth: 1))
        .sensoryFeedback(.selection, trigger: selection)
    }
}

/// A clean line+area trend chart.
struct SignalChart: View {
    /// (x label, value)
    let points: [(label: String, value: Double)]
    var height: CGFloat = 120

    var body: some View {
        Chart {
            ForEach(Array(points.enumerated()), id: \.offset) { i, p in
                AreaMark(x: .value("i", i), y: .value("v", p.value))
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(LinearGradient(
                        colors: [RinklerColors.signalBlue.opacity(0.35), RinklerColors.signalBlue.opacity(0.02)],
                        startPoint: .top, endPoint: .bottom))
                LineMark(x: .value("i", i), y: .value("v", p.value))
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(RinklerColors.signalBlue)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
            }
        }
        .chartYAxis(.hidden)
        .chartXAxis {
            let step = max(1, points.count / 4)
            AxisMarks(values: Array(stride(from: 0, to: points.count, by: step))) { value in
                if let i = value.as(Int.self), i < points.count {
                    AxisValueLabel {
                        Text(points[i].label)
                            .font(.system(size: 9))
                            .foregroundStyle(RinklerColors.signalTextFaint)
                    }
                }
            }
        }
        .frame(height: height)
    }
}

extension View {
    /// Frosted floating bar (bottom action bar).
    func floatingBar(cornerRadius: CGFloat = 24) -> some View {
        self
            .padding(RinklerSpacing.md)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(RinklerColors.signalBorder, lineWidth: 1))
    }
}

// MARK: - Signature hero

/// Rinkler's ownable hero — the signal ring around the "pause the scroll" bars,
/// which **sharpens and starts to orbit as the streak grows**. Our answer to
/// Opal's gems, but stark and on-brand: blue accent only, no gem, no glow.
struct ClaritySignal: View {
    var streak: Int
    var size: CGFloat = 150

    @State private var orbit = false

    /// Ring fills from a faint sliver toward full over the first two weeks.
    private var progress: Double { min(1, 0.12 + Double(min(max(streak, 0), 14)) / 14 * 0.88) }
    /// Past a week, a satellite begins to orbit — a quiet reward.
    private var orbiting: Bool { streak >= 7 }

    var body: some View {
        ZStack {
            SignalRing(progress: progress, lineWidth: size * 0.06) {
                HStack(spacing: size * 0.055) {
                    Capsule().fill(RinklerColors.signalBlue).frame(width: size * 0.06, height: size * 0.22)
                    Capsule().fill(RinklerColors.signalBlue).frame(width: size * 0.06, height: size * 0.22)
                }
                .opacity(0.35 + progress * 0.65)
            }

            if orbiting {
                Circle()
                    .fill(RinklerColors.signalBlue)
                    .frame(width: size * 0.07, height: size * 0.07)
                    .offset(y: -size / 2)
                    .rotationEffect(.degrees(orbit ? 360 : 0))
                    .animation(.linear(duration: 7).repeatForever(autoreverses: false), value: orbit)
            }
        }
        .frame(width: size, height: size)
        .onAppear { orbit = true }
    }
}

#Preview {
    ZStack {
        SignalBackground()
        VStack(spacing: 24) {
            ClaritySignal(streak: 9)
            RinklerStatRow(stats: [("Time back", "3h 12m", nil),
                                   ("Pulls dodged", "47", RinklerColors.signalBlue),
                                   ("Streak", "9d", nil)])
            SignalChart(points: (0..<7).map { (["S","M","T","W","T","F","S"][$0], Double.random(in: 1...5)) })
                .padding(.horizontal)
        }
        .padding()
    }
}
