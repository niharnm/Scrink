import SwiftUI

@main
struct RinklerApp: App {
    @StateObject private var vpnManager = VPNManager()
    @StateObject private var sessions = FocusSessionStore()
    @StateObject private var schedules = ScheduleStore()
    @StateObject private var commitment = CommitmentStore()
    @StateObject private var focusSystem = FocusSystemStore()
    @State private var path = NavigationPath()
    @State private var authStore = AuthStore()
    @State private var showStoryIntro = !Story.hasSeenIntro

    init() {
        UserDefaults(suiteName: RinklerConstants.appGroupID)?
            .register(defaults: [
                RinklerConstants.blockInstagramShortVideoEnabledKey: true,
                RinklerConstants.blockTikTokShortVideoEnabledKey: true,
            ])

        #if DEBUG
        // Deterministic jump for screenshot/UI verification:
        //   -uiPreview today | home | journey | settings | signin | schedules
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-uiPreview"), i + 1 < args.count {
            Story.hasSeenIntro = true
            _showStoryIntro = State(initialValue: false)
            // Skip the onboarding gate so previews land directly in the shell.
            UserDefaults(suiteName: RinklerConstants.appGroupID)?
                .set(true, forKey: "hasCompletedOnboarding")
            var p = NavigationPath()
            switch args[i + 1] {
            case "home": p.append(Route.home)
            case "journey": p.append(Route.today); p.append(Route.storyJourney)
            case "settings": p.append(Route.today); p.append(Route.settings)
            case "signin": p.append(Route.magicSignIn)
            case "schedules":
                let sample = FocusSchedule(label: "Evening wind-down", weekdays: [2, 3, 4, 5, 6],
                                           hour: 20, minute: 0, durationMinutes: 45,
                                           strictness: .focused, platforms: FocusPlatform.allCases)
                if let data = try? JSONEncoder().encode([sample]) {
                    UserDefaults.standard.set(data, forKey: "rinkler.focusSchedules")
                }
                p.append(Route.today); p.append(Route.schedules)
            default: p.append(Route.today)
            }
            _path = State(initialValue: p)
        }
        #endif
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
                                    },
                                    onJourney: {
                                        path.append(Route.storyJourney)
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
                                SettingsScreen(onReplayIntro: {
                                    path.append(Route.storyIntro)
                                }, onSchedules: {
                                    path.append(Route.schedules)
                                })
                            case .trafficDashboard:
                                TrafficDashboardView()
                            case .extensionLog:
                                ExtensionLogView()
                            case .schedules:
                                SchedulesScreen()
                            case .storyJourney:
                                StoryJourneyView()
                            case .storyIntro:
                                StoryIntroView(onFinish: {
                                    if !path.isEmpty { path.removeLast() }
                                })
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
            // Cinematic Story intro plays once over whatever is shown (onboarding
            // for new users, the shell for returning ones) before they proceed.
            .fullScreenCover(isPresented: $showStoryIntro) {
                StoryIntroView(onFinish: { showStoryIntro = false })
                    .preferredColorScheme(.dark)
            }
            .environment(authStore)
            .environmentObject(vpnManager)
            .environmentObject(sessions)
            .environmentObject(schedules)
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
