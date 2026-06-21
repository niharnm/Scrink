import SwiftUI

struct AppIconCircle: View {
    let iconName: String
    var size: CGFloat = RinklerSpacing.appIconMedium
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
                            .foregroundStyle(RinklerColors.skyBlue)
                    } else if let platform = platform {
                        SocialMediaIcon(platform: platform, size: size * 0.7)
                    } else {
                        Image(systemName: iconName)
                            .font(.system(size: size * 0.35))
                            .foregroundStyle(RinklerColors.skyBlue)
                    }
                }
            )
    }
}

#Preview {
    ZStack {
        RinklerColors.skyGradient.ignoresSafeArea()
        HStack(spacing: 20) {
            AppIconCircle(iconName: "camera.fill")
            AppIconCircle(iconName: "shield.fill")
            AppIconCircle(iconName: "plus", isAddButton: true)
        }
    }
}
