import SwiftUI

@main
struct RinklerApp: App {
    @StateObject private var vpnManager = VPNManager()
    @StateObject private var sessions = FocusSessionStore()
    @StateObject private var commitment = CommitmentStore()
    @StateObject private var focusSystem = FocusSystemStore()
    @StateObject private var appearance = AppearanceStore()
    @StateObject private var screenTime = ScreenTimeManager()
    @StateObject private var strictMode = StrictModeStore()
    @StateObject private var health = HealthManager()
    @StateObject private var autoMode = AutoModeEngine()
    @StateObject private var friendControl = FriendControlStore()
    @StateObject private var blockedApps = BlockedAppsStore()
    @State private var path = NavigationPath()
    @State private var authStore = AuthStore()
    @State private var showSplash = true
    @Environment(\.scenePhase) private var scenePhase

    /// DEBUG screenshot/dev deep-link, set from `-uiPreview <screen>`. nil in
    /// normal runs and in release builds.
    @State private var previewScreen: String? = nil

    init() {
        UserDefaults(suiteName: RinklerConstants.appGroupID)?
            .register(defaults: [
                RinklerConstants.blockInstagramShortVideoEnabledKey: true,
                RinklerConstants.blockTikTokShortVideoEnabledKey: true,
                RinklerConstants.blockAdsTrackersEnabledKey: true,
            ])

        #if DEBUG
        // Jump straight to a screen for screenshots / UI verification:
        //   -uiPreview today | commitment
        let args = ProcessInfo.processInfo.arguments
        // Force an appearance for screenshots: -appearance light | dark | system
        if let a = args.firstIndex(of: "-appearance"), a + 1 < args.count {
            UserDefaults.standard.set(args[a + 1], forKey: "rinkler.appearanceMode")
        }
        if let i = args.firstIndex(of: "-uiPreview"), i + 1 < args.count {
            let screen = args[i + 1]
            _previewScreen = State(initialValue: screen)
            if screen != "commitment" && screen != "block" {
                UserDefaults(suiteName: RinklerConstants.appGroupID)?
                    .set(true, forKey: "hasCompletedOnboarding")
                var p = NavigationPath()
                p.append(Route.today)
                _path = State(initialValue: p)
            }
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
            Group {
                if previewScreen == "commitment" {
                    CommitmentUnlockSheet(cooldownSeconds: 8, onConfirm: {}, onCancel: {})
                } else if previewScreen == "block" {
                    BlockScreen(appName: "Instagram", surface: "Reels", pullsDodged: 47,
                                minutesReclaimed: 72, streakDays: 5, onLetMeIn: {}, onDone: {})
                } else if previewScreen == "settings" {
                    NavigationStack { SettingsScreen() }
                } else if previewScreen == "privacy" {
                    LegalScreen(doc: LegalContent.privacy)
                } else if previewScreen == "terms" {
                    LegalScreen(doc: LegalContent.terms)
                } else if previewScreen == "strict" {
                    NavigationStack { StrictModeSetupScreen() }
                } else if previewScreen == "control" {
                    NavigationStack { ControlScreen() }
                } else if previewScreen == "apps" {
                    NavigationStack { AppsScreen() }
                } else if previewScreen == "friend" {
                    NavigationStack { FriendControlScreen() }
                } else if previewScreen == "signin" {
                    NavigationStack { MagicSignInScreen() }
                } else if focusSystem.hasCompletedOnboarding {
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
                                MagicSignInScreen(onSignedIn: {
                                    path = NavigationPath()
                                    path.append(Route.today)
                                })
                            case .codeVerification(let email):
                                CodeVerificationScreen(email: email, onVerified: {
                                    path = NavigationPath()
                                    path.append(Route.today)
                                })
                            case .settings:
                                SettingsScreen(onLogout: {
                                    path = NavigationPath()
                                    path.append(Route.magicSignIn)
                                })
                            case .strictModeSetup:
                                StrictModeSetupScreen()
                            case .friendControl:
                                FriendControlScreen()
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
            .environmentObject(appearance)
            .environmentObject(screenTime)
            .environmentObject(strictMode)
            .environmentObject(health)
            .environmentObject(autoMode)
            .environmentObject(friendControl)
            .environmentObject(blockedApps)
            .preferredColorScheme(appearance.mode.colorScheme)
            .task {
                SVGCache.shared.preload(svgNames: ["instagram"])
            }
            .task {
                await authStore.listenForAuthChanges()
            }
            .task {
                // Wire the new stores once the environment exists, re-derive any
                // open Strict window, and start health-driven Automatic Mode.
                strictMode.configure(vpn: vpnManager, commitment: commitment, screenTime: screenTime)
                strictMode.tickIfExpired()
                autoMode.configure(health: health, screenTime: screenTime)
                friendControl.tick()        // pull any active friend-control limits
                blockedApps.configure(screenTime: screenTime)   // re-apply whole-app shield
                await RuleRegistry.sync()   // hot-update the block rule pack
                health.refreshAvailability()
                if health.isAuthorized {
                    health.enableBackgroundDelivery {
                        await autoMode.evaluate(trigger: .observer)
                    }
                    await autoMode.evaluate(trigger: .foreground)
                }
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    strictMode.tickIfExpired()
                    friendControl.tick()
                    Task { await autoMode.evaluate(trigger: .foreground) }
                }
            }
            .onAppear {
                vpnManager.setup()
            }

                if showSplash && previewScreen == nil {
                    SplashView(onFinished: {
                        advanceAfterSplash()
                        withAnimation(.easeInOut(duration: 0.45)) { showSplash = false }
                    })
                    .transition(.opacity)
                    .zIndex(10)
                }
            }
        }
    }

    /// After the opening animation, walk straight into the app — no tap on the
    /// landing page. Returning users land on Today; signed-out users hit sign-in;
    /// first-timers fall through to onboarding (path stays empty).
    private func advanceAfterSplash() {
        guard focusSystem.hasCompletedOnboarding, path.isEmpty else { return }
        path.append(authStore.isLoggedIn ? Route.today : Route.magicSignIn)
    }
}
