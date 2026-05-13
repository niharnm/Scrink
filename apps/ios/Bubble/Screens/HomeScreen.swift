import SwiftUI
import NetworkExtension

struct HomeScreen: View {
    @Environment(AppStore.self) private var store
    @Environment(AuthStore.self) private var authStore
    @EnvironmentObject private var vpnManager: VPNManager
    var onSelectApp: (BlockedApp) -> Void
    var onSignIn: (() -> Void)? = nil
    var onSettings: (() -> Void)? = nil
    var onTrafficDashboard: (() -> Void)? = nil

    var body: some View {
        ZStack {
            SkyBackgroundView()

            AppCluster(
                apps: store.apps,
                onTapApp: { app in
                    onSelectApp(app)
                },
                onTapAdd: {
                    print("Add app tapped")
                },
                showAddButton: false
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Header with VPN status
            VStack {
                HStack {
                    HeaderBar()
                        .padding(.top, BubbleSpacing.md + 10)
                        .padding(.leading, BubbleSpacing.lg + 5)
                    Spacer()

                    // VPN status dot + action buttons
                    HStack(spacing: BubbleSpacing.sm) {
                        // VPN status indicator
                        Circle()
                            .fill(VPNManager.statusColor(for: vpnManager.vpnStatus))
                            .frame(width: 10, height: 10)

                        // Traffic dashboard button
                        if let onTrafficDashboard = onTrafficDashboard {
                            Button {
                                onTrafficDashboard()
                            } label: {
                                Image(systemName: "chart.bar.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.white)
                            }
                        }

                        // Settings gear button
                        if let onSettings = onSettings {
                            Button {
                                onSettings()
                            } label: {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.white)
                            }
                        }

                        // Sign in button (only show if not logged in)
                        if !authStore.isLoggedIn, let onSignIn = onSignIn {
                            Button {
                                onSignIn()
                            } label: {
                                Text("Sign In")
                                    .font(BubbleFonts.coolvetica(size: 16))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, BubbleSpacing.md)
                                    .padding(.vertical, BubbleSpacing.sm)
                                    .background(BubbleColors.skyBlue)
                                    .clipShape(RoundedRectangle(cornerRadius: BubbleSpacing.buttonCornerRadius))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: BubbleSpacing.buttonCornerRadius)
                                            .strokeBorder(Color.white, lineWidth: 1)
                                    )
                            }
                        }
                    }
                    .padding(.top, BubbleSpacing.md + 10)
                    .padding(.trailing, BubbleSpacing.lg + 5)
                }
                Spacer()
            }

        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    HomeScreen(onSelectApp: { _ in }, onSignIn: {})
        .environment(AppStore())
        .environment(GridPositionStore())
        .environment(AuthStore())
        .environmentObject(VPNManager())
}
