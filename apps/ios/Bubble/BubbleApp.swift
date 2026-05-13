import SwiftUI

@main
struct BubbleApp: App {
    @StateObject private var vpnManager = VPNManager()
    @State private var path = NavigationPath()
    @State private var store = AppStore()
    @State private var gridPositionStore = GridPositionStore()
    @State private var authStore = AuthStore()

    init() {
        UserDefaults(suiteName: BubbleConstants.appGroupID)?
            .register(defaults: [BubbleConstants.blockReelsEnabledKey: true])
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
                            onSelectApp: { app in
                                path.append(Route.blockingOptions(appId: app.id))
                            },
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
                    case .blockingOptions(let appId):
                        BlockingOptionsScreen(appId: appId)
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
            .environment(store)
            .environment(gridPositionStore)
            .environment(authStore)
            .environmentObject(vpnManager)
            .preferredColorScheme(.dark)
            .task {
                SVGCache.shared.preload(svgNames: ["instagram", "kalshi", "fanduel"])
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
