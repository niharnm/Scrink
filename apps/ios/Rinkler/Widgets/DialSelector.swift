import SwiftUI

struct DialSelector: View {
    let app: BlockedApp
    var onToggleOption: (String) -> Void

    private let radius = RinklerSpacing.dialRadius

    var body: some View {
        ZStack {
            // Outer ring
            Circle()
                .strokeBorder(RinklerColors.white30, lineWidth: 2)
                .frame(width: radius * 2, height: radius * 2)

            // Center app icon
            AppIconCircle(
                iconName: app.iconName,
                size: RinklerSpacing.dialCenterIcon,
                platform: app.platform
            )

            // Options positioned around the ring
            ForEach(Array(app.options.enumerated()), id: \.element.id) { index, option in
                let angle = angleFor(index: index, total: app.options.count)

                DialOptionRinkler(
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
        .frame(width: radius * 2 + RinklerSpacing.dialOptionSize,
               height: radius * 2 + RinklerSpacing.dialOptionSize)
    }

    private func angleFor(index: Int, total: Int) -> CGFloat {
        let startAngle: CGFloat = -.pi / 2 // start from top
        let step = (2 * .pi) / CGFloat(total)
        return startAngle + step * CGFloat(index)
    }
}

struct DialOptionRinkler: View {
    let label: String
    let isEnabled: Bool
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(label)
                .font(RinklerFonts.optionLabel)
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isEnabled ? RinklerColors.skyBlue : Color.clear)
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
        RinklerColors.skyGradient.ignoresSafeArea()
        DialSelector(
            app: AppStore().apps[0],
            onToggleOption: { _ in }
        )
    }
}
