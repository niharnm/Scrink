import SwiftUI

struct DialSelector: View {
    let app: BlockedApp
    var onToggleOption: (String) -> Void

    private let radius = BubbleSpacing.dialRadius

    var body: some View {
        ZStack {
            // Outer ring
            Circle()
                .strokeBorder(BubbleColors.white30, lineWidth: 2)
                .frame(width: radius * 2, height: radius * 2)

            // Center app icon
            AppIconCircle(
                iconName: app.iconName,
                size: BubbleSpacing.dialCenterIcon,
                platform: app.platform
            )

            // Options positioned around the ring
            ForEach(Array(app.options.enumerated()), id: \.element.id) { index, option in
                let angle = angleFor(index: index, total: app.options.count)

                DialOptionBubble(
                    label: option.label,
                    isEnabled: option.isEnabled,
                    onTap: { onToggleOption(option.id) }
                )
                .offset(
                    x: radius * cos(angle),
                    y: radius * sin(angle)
                )
            }
        }
        .frame(width: radius * 2 + BubbleSpacing.dialOptionSize,
               height: radius * 2 + BubbleSpacing.dialOptionSize)
    }

    private func angleFor(index: Int, total: Int) -> CGFloat {
        let startAngle: CGFloat = -.pi / 2 // start from top
        let step = (2 * .pi) / CGFloat(total)
        return startAngle + step * CGFloat(index)
    }
}

struct DialOptionBubble: View {
    let label: String
    let isEnabled: Bool
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(label)
                .font(BubbleFonts.optionLabel)
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isEnabled ? BubbleColors.skyBlue : Color.clear)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(Color.white, lineWidth: isEnabled ? 1 : 0.5)
                )
        }
    }
}

#Preview {
    ZStack {
        BubbleColors.skyGradient.ignoresSafeArea()
        DialSelector(
            app: AppStore().apps[0],
            onToggleOption: { _ in }
        )
    }
}
