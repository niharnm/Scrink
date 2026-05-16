import SwiftUI

@main
struct BubbleApp: App {
    @StateObject private var vpnManager = VPNManager()
    @State private var path = NavigationPath()
    @State private var authStore = AuthStore()

    init() {
        UserDefaults(suiteName: BubbleConstants.appGroupID)?
            .register(defaults: [
                BubbleConstants.blockInstagramShortVideoEnabledKey: true,
                BubbleConstants.blockTikTokShortVideoEnabledKey: true,
                BubbleConstants.blockYouTubeShortVideoEnabledKey: true,
            ])
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $path) {
                LandingPage(onGo: {
                    if authStore.isLoggedIn {
                        path.append(Route.home)
                    } else {
                        path.append(Route.magicSignIn)
                    }
                })
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .home:
                        HomeScreen(
                            onSignIn: {
                                path.append(Route.magicSignIn)
                            },
                            onSettings: {
                                path.append(Route.settings)
                            },
                            onTrafficDashboard: {
                                path.append(Route.trafficDashboard)
                            }
                        )
                    case .magicSignIn:
                        MagicSignInScreen(
                            onCodeSent: { email in
                                path.append(Route.codeVerification(email: email))
                            }
                        )
                    case .codeVerification(let email):
                        CodeVerificationScreen(email: email, onVerified: {
                            path = NavigationPath()
                            path.append(Route.home)
                        })
                    case .settings:
                        SettingsScreen()
                    case .trafficDashboard:
                        TrafficDashboardView()
                    case .extensionLog:
                        ExtensionLogView()
                    }
                }
            }
            .environment(authStore)
            .environmentObject(vpnManager)
            .preferredColorScheme(.dark)
            .task {
                SVGCache.shared.preload(svgNames: ["instagram"])
            }
            .task {
                await authStore.listenForAuthChanges()
            }
            .onAppear {
                vpnManager.setup()
            }
        }
    }
}
