import SwiftUI

@main
struct RinklerApp: App {
    @StateObject private var vpnManager = VPNManager()
    @StateObject private var sessions = FocusSessionStore()
    @StateObject private var commitment = CommitmentStore()
    @StateObject private var focusSystem = FocusSystemStore()
    @State private var path = NavigationPath()
    @State private var authStore = AuthStore()

    init() {
        UserDefaults(suiteName: RinklerConstants.appGroupID)?
            .register(defaults: [
                RinklerConstants.blockInstagramShortVideoEnabledKey: true,
                RinklerConstants.blockTikTokShortVideoEnabledKey: true,
            ])
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if focusSystem.hasCompletedOnboarding {
                NavigationStack(path: $path) {
                LandingPage(onGo: {
                    if authStore.isLoggedIn {
                        path.append(Route.today)
                    } else {
                        path.append(Route.magicSignIn)
                    }
                })
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .today:
                        MainTabView(
                            onSettings: { path.append(Route.settings) },
                            onStartSession: { path.append(Route.focusSetup) },
                            onTrafficDashboard: { path.append(Route.trafficDashboard) }
                        )
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
                            },
                            onStartSession: {
                                path.append(Route.focusSetup)
                            },
                            onResumeSession: {
                                path.append(Route.activeSession)
                            }
                        )
                    case .focusSetup:
                        FocusSetupScreen(onBegin: {
                            // Replace setup with the active session so Back from
                            // the session returns home, not to setup.
                            path.removeLast()
                            path.append(Route.activeSession)
                        })
                    case .activeSession:
                        ActiveSessionScreen(onEnd: {
                            path.removeLast()
                            path.append(Route.sessionRecap)
                        })
                    case .sessionRecap:
                        SessionRecapScreen(onDone: {
                            // Reset cleanly back to the Today tab shell.
                            path = NavigationPath()
                            path.append(Route.today)
                        })
                    case .magicSignIn:
                        MagicSignInScreen(
                            onCodeSent: { email in
                                path.append(Route.codeVerification(email: email))
                            },
                            onContinueOffline: {
                                path = NavigationPath()
                                path.append(Route.today)
                            }
                        )
                    case .codeVerification(let email):
                        CodeVerificationScreen(email: email, onVerified: {
                            path = NavigationPath()
                            path.append(Route.today)
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
                } else {
                    OnboardingFlow(onFinish: {
                        path = NavigationPath()
                        path.append(Route.today)
                    })
                }
            }
            .environment(authStore)
            .environmentObject(vpnManager)
            .environmentObject(sessions)
            .environmentObject(commitment)
            .environmentObject(focusSystem)
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
