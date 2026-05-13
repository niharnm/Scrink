import SwiftUI

struct AppIconCircle: View {
    let iconName: String
    var size: CGFloat = BubbleSpacing.appIconMedium
    var isAddButton: Bool = false
    var platform: String? = nil

    var body: some View {
        Circle()
            .fill(.white)
            .frame(width: size, height: size)
            .overlay(
                Group {
                    if isAddButton {
                        Image(systemName: "plus")
                            .font(.system(size: size * 0.35, weight: .bold))
                            .foregroundStyle(BubbleColors.skyBlue)
                    } else if let platform = platform {
                        SocialMediaIcon(platform: platform, size: size * 0.7)
                    } else {
                        Image(systemName: iconName)
                            .font(.system(size: size * 0.35))
                            .foregroundStyle(BubbleColors.skyBlue)
                    }
                }
            )
    }
}

#Preview {
    ZStack {
        BubbleColors.skyGradient.ignoresSafeArea()
        HStack(spacing: 20) {
            AppIconCircle(iconName: "camera.fill")
            AppIconCircle(iconName: "shield.fill")
            AppIconCircle(iconName: "plus", isAddButton: true)
        }
    }
}
