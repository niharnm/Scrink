import SwiftUI

struct HomeScreen: View {
    @Environment(AuthStore.self) private var authStore
    @EnvironmentObject private var vpnManager: VPNManager

    @AppStorage(BubbleConstants.blockReelsEnabledKey,
                store: UserDefaults(suiteName: BubbleConstants.appGroupID))
    private var blockShortVideo: Bool = true

    var onSignIn: (() -> Void)? = nil
    var onSettings: (() -> Void)? = nil
    var onTrafficDashboard: (() -> Void)? = nil

    var body: some View {
        ZStack {
            SkyBackgroundView()

            ScrollView {
                VStack(alignment: .leading, spacing: BubbleSpacing.lg) {
                    header
                    protectionCard
                    filterCard
                    accountCard
                }
                .padding(.horizontal, BubbleSpacing.lg)
                .padding(.top, BubbleSpacing.xl)
                .padding(.bottom, BubbleSpacing.xxl)
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    private var header: some View {
        HStack(alignment: .center) {
            HeaderBar()
            Spacer()
            HStack(spacing: BubbleSpacing.sm) {
                iconButton(systemName: "chart.bar.fill", label: "Traffic dashboard", action: onTrafficDashboard)
                iconButton(systemName: "gearshape.fill", label: "Settings", action: onSettings)
            }
        }
    }

    private var protectionCard: some View {
        VStack(alignment: .leading, spacing: BubbleSpacing.md) {
            HStack(alignment: .center, spacing: BubbleSpacing.md) {
                Image(systemName: vpnManager.vpnStatus == .connected ? "shield.fill" : "shield.slash.fill")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(VPNManager.statusColor(for: vpnManager.vpnStatus))
                    .frame(width: 52, height: 52)
                    .background(Color.white.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: BubbleSpacing.xs) {
                    Text(protectionTitle)
                        .font(BubbleFonts.coolvetica(size: 24))
                        .foregroundStyle(.white)
                    Text(protectionSubtitle)
                        .font(BubbleFonts.coolvetica(size: 15))
                        .foregroundStyle(BubbleColors.white60)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Button(action: { vpnManager.toggleVPN() }) {
                Text(vpnButtonTitle)
                    .font(BubbleFonts.pupok(size: 22))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        vpnManager.vpnStatus == .connected
                            ? Color.red.opacity(0.9)
                            : BubbleColors.skyBlue
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .strokeBorder(Color.white.opacity(0.8), lineWidth: 1)
                    )
            }
            .disabled(vpnManager.isPreparingProfile)
            .opacity(vpnManager.isPreparingProfile ? 0.7 : 1)
        }
        .padding(BubbleSpacing.lg)
        .background(Color.black.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
        )
    }

    private var filterCard: some View {
        VStack(alignment: .leading, spacing: BubbleSpacing.md) {
            HStack(alignment: .center, spacing: BubbleSpacing.md) {
                SocialMediaIcon(platform: "instagram", size: 34)
                    .frame(width: 52, height: 52)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: BubbleSpacing.xs) {
                    Text("Instagram short video")
                        .font(BubbleFonts.coolvetica(size: 20))
                        .foregroundStyle(.white)
                    Text("Limits tracked Instagram video domains after 0.5 MB by default.")
                        .font(BubbleFonts.coolvetica(size: 14))
                        .foregroundStyle(BubbleColors.white60)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: BubbleSpacing.sm)

                Toggle("", isOn: $blockShortVideo)
                    .labelsHidden()
            }

            if let onSettings {
                Button {
                    onSettings()
                } label: {
                    Text("Adjust advanced thresholds")
                        .font(BubbleFonts.coolvetica(size: 15))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, BubbleSpacing.sm)
                        .background(Color.white.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
        }
        .padding(BubbleSpacing.lg)
        .background(Color.black.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
        )
    }

    private var accountCard: some View {
        VStack(alignment: .leading, spacing: BubbleSpacing.md) {
            Text(authStore.isLoggedIn ? "Signed in" : "Cloud sync is off")
                .font(BubbleFonts.coolvetica(size: 20))
                .foregroundStyle(.white)

            Text(accountSubtitle)
                .font(BubbleFonts.coolvetica(size: 14))
                .foregroundStyle(BubbleColors.white60)
                .fixedSize(horizontal: false, vertical: true)

            if authStore.isLoggedIn {
                if let onTrafficDashboard {
                    Button {
                        onTrafficDashboard()
                    } label: {
                        Text("View traffic dashboard")
                            .font(BubbleFonts.coolvetica(size: 16))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, BubbleSpacing.sm)
                            .background(Color.white.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
            } else if let onSignIn {
                Button {
                    onSignIn()
                } label: {
                    Text("Sign in")
                        .font(BubbleFonts.coolvetica(size: 16))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, BubbleSpacing.sm)
                        .background(BubbleColors.skyBlue)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
        }
        .padding(BubbleSpacing.lg)
        .background(Color.black.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
        )
    }

    private func iconButton(systemName: String, label: String, action: (() -> Void)?) -> some View {
        Button {
            action?()
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(Color.white.opacity(0.12))
                .clipShape(Circle())
        }
        .disabled(action == nil)
        .accessibilityLabel(label)
    }

    private var protectionTitle: String {
        switch vpnManager.vpnStatus {
        case .connected:
            return "Protection is on"
        case .connecting, .reasserting:
            return "Protection is starting"
        case .disconnecting:
            return "Protection is stopping"
        case .invalid:
            return "VPN profile needs setup"
        default:
            return "Protection is off"
        }
    }

    private var protectionSubtitle: String {
        switch vpnManager.vpnStatus {
        case .connected:
            return "Rinkler is filtering supported traffic on this device."
        case .connecting, .reasserting:
            return "iOS is preparing the local VPN tunnel."
        case .disconnecting:
            return "The local VPN tunnel is shutting down."
        case .invalid:
            return "Open Settings if iOS needs permission to create the VPN profile."
        default:
            return "Start protection to route traffic through the local filter."
        }
    }

    private var vpnButtonTitle: String {
        if vpnManager.isPreparingProfile {
            return "PREPARING..."
        }
        return vpnManager.vpnStatus == .connected ? "STOP PROTECTION" : "START PROTECTION"
    }

    private var accountSubtitle: String {
        if authStore.isLoggedIn {
            return authStore.userEmail.isEmpty
                ? "Traffic summaries can sync to your Rinkler dashboard."
                : "Signed in as \(authStore.userEmail). Traffic summaries can sync to your dashboard."
        }
        return "Sign in to sync traffic summaries. VPN filtering still runs locally without an account."
    }
}

#Preview {
    HomeScreen(onSignIn: {})
        .environment(AuthStore())
        .environmentObject(VPNManager())
}
