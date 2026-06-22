import SwiftUI
import NetworkExtension
import StoreKit

struct SettingsScreen: View {
    var onLogout: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview
    @Environment(AuthStore.self) private var authStore
    @EnvironmentObject private var vpnManager: VPNManager
    @EnvironmentObject private var commitment: CommitmentStore
    @EnvironmentObject private var focusSystem: FocusSystemStore
    @EnvironmentObject private var appearance: AppearanceStore
    @EnvironmentObject private var screenTime: ScreenTimeManager
    @EnvironmentObject private var strictMode: StrictModeStore
    @EnvironmentObject private var autoMode: AutoModeEngine
    @EnvironmentObject private var health: HealthManager

    @State private var showResetOnboarding = false
    @State private var showSignOut = false
    @State private var legalDoc: LegalContent.Doc?

    @AppStorage(RinklerConstants.blockInstagramShortVideoEnabledKey,
                store: UserDefaults(suiteName: RinklerConstants.appGroupID))
    private var blockInstagramShortVideo: Bool = true

    @AppStorage(RinklerConstants.blockTikTokShortVideoEnabledKey,
                store: UserDefaults(suiteName: RinklerConstants.appGroupID))
    private var blockTikTokShortVideo: Bool = true

    @StateObject private var domainThresholds = DomainThresholdsStore()

    @State private var showExtensionLog = false

    var body: some View {
        ZStack {
            SignalBackground()

            ScrollView {
                VStack(spacing: RinklerSpacing.lg) {
                    // VPN Status Header
                    vpnStatusSection

                    // VPN Toggle Button
                    vpnToggleButton

                    // Strict Mode (total lockdown)
                    strictModeSection

                    // Friend remote control
                    friendControlSection

                    // Automatic, health-aware tightening
                    automaticModeSection

                    // Permissions the app needs (Screen Time access, etc.)
                    permissionsSection

                    // Light / Dark / System
                    appearanceSection

                    // Focus System (rules created during onboarding)
                    focusSystemSection

                    // Commitment mode (friction on turning protection OFF)
                    commitmentSection

                    // Short-form filter toggles
                    shortVideoFiltersSection

                    // Domain Thresholds
                    if hasActiveShortVideoFilter {
                        domainThresholdsSection
                    }

                    // Privacy, Terms, Contact, Version
                    aboutSection

                    // Sign in / out
                    accountSection

                    #if DEBUG
                    appLogSection

                    extensionLogButton
                    #endif
                }
                .padding(.horizontal, RinklerSpacing.lg)
                .padding(.top, RinklerSpacing.xl)
                .padding(.bottom, 100)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    BackArrowView()
                }
            }
        }
        .sheet(isPresented: $showExtensionLog) {
            extensionLogSheet
        }
        .sheet(item: $legalDoc) { doc in
            LegalScreen(doc: doc)
        }
    }

    // MARK: - Appearance

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("APPEARANCE")
                .font(RinklerFonts.sans(12, .semibold))
                .foregroundStyle(RinklerColors.signalTextDim)

            HStack(spacing: 8) {
                ForEach(AppearanceStore.Mode.allCases) { mode in
                    Button { appearance.mode = mode } label: {
                        VStack(spacing: 6) {
                            Image(systemName: mode.icon)
                                .font(.system(size: 18, weight: .semibold))
                            Text(mode.title)
                                .font(RinklerFonts.sans(13, .medium))
                        }
                        .foregroundStyle(appearance.mode == mode ? RinklerColors.signalOnInk : RinklerColors.signalText)
                        .frame(maxWidth: .infinity).frame(height: 66)
                        .background(appearance.mode == mode ? AnyView(RinklerColors.signalInk) : AnyView(RinklerColors.signalCard))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(appearance.mode == mode ? Color.clear : RinklerColors.signalBorder, lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Strict Mode

    private var strictModeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("STRICT MODE")
                .font(RinklerFonts.sans(12, .semibold))
                .foregroundStyle(RinklerColors.signalTextDim)

            if strictMode.isActive {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.fill").foregroundStyle(RinklerColors.signalBlue)
                        Text("Locked — \(strictMode.remainingLabel)")
                            .font(RinklerFonts.sans(16, .semibold))
                            .foregroundStyle(RinklerColors.signalText)
                    }
                    Text("Your controls are locked until \(strictMode.endLabel). The only way out before then is iOS Settings → Screen Time.")
                        .font(RinklerFonts.sans(12, .regular))
                        .foregroundStyle(RinklerColors.signalTextDim)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(RinklerSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .signalCard(cornerRadius: 16)
            } else {
                NavigationLink(value: Route.strictModeSetup) {
                    HStack(spacing: RinklerSpacing.md) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(RinklerColors.signalBlue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Lock it down")
                                .font(RinklerFonts.sans(16, .semibold))
                                .foregroundStyle(RinklerColors.signalText)
                            Text("Lock your limits for a set stretch. No backing out from here.")
                                .font(RinklerFonts.sans(12, .regular))
                                .foregroundStyle(RinklerColors.signalTextDim)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: RinklerSpacing.sm)
                        Image(systemName: "chevron.right").foregroundStyle(RinklerColors.signalTextFaint)
                    }
                    .padding(RinklerSpacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .signalCard(cornerRadius: 16)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Friend control

    private var friendControlSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("FRIEND CONTROL")
                .font(RinklerFonts.sans(12, .semibold))
                .foregroundStyle(RinklerColors.signalTextDim)
            NavigationLink(value: Route.friendControl) {
                HStack(spacing: RinklerSpacing.md) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(RinklerColors.signalBlue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Let a friend run your limits")
                            .font(RinklerFonts.sans(16, .semibold))
                            .foregroundStyle(RinklerColors.signalText)
                        Text("Hand someone a code; they tighten your limits for a window you pick.")
                            .font(RinklerFonts.sans(12, .regular))
                            .foregroundStyle(RinklerColors.signalTextDim)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: RinklerSpacing.sm)
                    Image(systemName: "chevron.right").foregroundStyle(RinklerColors.signalTextFaint)
                }
                .padding(RinklerSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .signalCard(cornerRadius: 16)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Automatic (health-aware) Mode

    private var automaticModeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("AUTOMATIC MODE")
                .font(RinklerFonts.sans(12, .semibold))
                .foregroundStyle(RinklerColors.signalTextDim)

            VStack(alignment: .leading, spacing: RinklerSpacing.sm) {
                HStack(spacing: RinklerSpacing.md) {
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(RinklerColors.signalBlue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Let it read the room")
                            .font(RinklerFonts.sans(16, .semibold))
                            .foregroundStyle(RinklerColors.signalText)
                        Text("When stress is up or you've barely moved, Rinkler tightens limits on its own. A read on your trends — not a medical reading. Stays on your phone.")
                            .font(RinklerFonts.sans(12, .regular))
                            .foregroundStyle(RinklerColors.signalTextDim)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: RinklerSpacing.sm)
                    Toggle("", isOn: $autoMode.enabled)
                        .labelsHidden().tint(RinklerColors.signalBlue)
                        .disabled(!health.isAuthorized || strictMode.isActive)
                }

                if health.isAvailable && !health.isAuthorized {
                    Button { Task { await connectHealth() } } label: {
                        Text("Hook up Apple Health")
                            .font(RinklerFonts.sans(14, .semibold))
                            .foregroundStyle(RinklerColors.signalBlue)
                    }
                } else if !health.isAvailable {
                    Text("No health data on this phone, sorry.")
                        .font(RinklerFonts.sans(12, .regular))
                        .foregroundStyle(RinklerColors.signalTextFaint)
                }

                if autoMode.enabled {
                    Divider().overlay(RinklerColors.signalBorder)
                    Text("SENSITIVITY")
                        .font(RinklerFonts.sans(11, .semibold))
                        .foregroundStyle(RinklerColors.signalTextDim)
                    Picker("Sensitivity", selection: $autoMode.sensitivity) {
                        ForEach(AutoSensitivity.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    if let reason = autoMode.lastState.reasons.first {
                        Text("Now: \(autoMode.lastState.tier.rawValue) — \(reason)")
                            .font(RinklerFonts.mono(11, .regular))
                            .foregroundStyle(RinklerColors.signalTextDim)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(RinklerSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .signalCard(cornerRadius: 16)

            if autoMode.enabled && !autoMode.log.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("RECENT")
                        .font(RinklerFonts.sans(11, .semibold))
                        .foregroundStyle(RinklerColors.signalTextDim)
                    ForEach(autoMode.log.prefix(6)) { entry in
                        Text("\(autoLogTime(entry.at))  \(entry.action) — \(entry.reasons.joined(separator: ", "))")
                            .font(RinklerFonts.mono(11, .regular))
                            .foregroundStyle(RinklerColors.signalTextDim)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(RinklerSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .signalCard(cornerRadius: 16)
            }
        }
    }

    private func connectHealth() async {
        let ok = await health.requestAuthorization()
        if ok {
            autoMode.enabled = true
            health.enableBackgroundDelivery { await autoMode.evaluate(trigger: .observer) }
            await autoMode.evaluate(trigger: .manual)
        }
    }

    private func autoLogTime(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "MMM d, h:mm a"; return f.string(from: d)
    }

    // MARK: - About & legal

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ABOUT & LEGAL")
                .font(RinklerFonts.sans(12, .semibold))
                .foregroundStyle(RinklerColors.signalTextDim)

            VStack(spacing: 0) {
                aboutRow("Rate Rinkler", icon: "star") { requestReview() }
                aboutDivider
                aboutRow("Privacy Policy", icon: "lock.shield") { legalDoc = LegalContent.privacy }
                aboutDivider
                aboutRow("Terms of Service", icon: "doc.text") { legalDoc = LegalContent.terms }
                aboutDivider
                aboutRow("Contact us", icon: "envelope") { openContact() }
            }
            .background(RinklerColors.signalCard)
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(RinklerColors.signalBorder, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            Text("Rinkler \(appVersion)")
                .font(RinklerFonts.mono(11, .regular))
                .foregroundStyle(RinklerColors.signalTextFaint)
                .frame(maxWidth: .infinity)
                .padding(.top, 2)
        }
    }

    // MARK: - Account

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ACCOUNT")
                .font(RinklerFonts.sans(12, .semibold))
                .foregroundStyle(RinklerColors.signalTextDim)

            Button {
                if authStore.isLoggedIn { showSignOut = true } else { onLogout?() }
            } label: {
                HStack(spacing: RinklerSpacing.md) {
                    Image(systemName: authStore.isLoggedIn ? "rectangle.portrait.and.arrow.right" : "person.crop.circle")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(authStore.isLoggedIn ? RinklerColors.signalWarning : RinklerColors.signalBlue)
                        .frame(width: 22)
                    Text(authStore.isLoggedIn ? "Sign out" : "Sign in")
                        .font(RinklerFonts.sans(15, .medium))
                        .foregroundStyle(authStore.isLoggedIn ? RinklerColors.signalWarning : RinklerColors.signalText)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(RinklerColors.signalTextFaint)
                }
                .padding(.horizontal, RinklerSpacing.md)
                .frame(height: 52)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RinklerColors.signalCard)
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(RinklerColors.signalBorder, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .alert("Sign out of Rinkler?", isPresented: $showSignOut) {
            Button("Cancel", role: .cancel) {}
            Button("Sign out", role: .destructive) {
                Task { await authStore.logout(); onLogout?() }
            }
        } message: {
            Text("Your rules and history stick around on this phone. Sign back in whenever.")
        }
    }

    private func aboutRow(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: RinklerSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(RinklerColors.signalBlue)
                    .frame(width: 22)
                Text(title)
                    .font(RinklerFonts.sans(15, .medium))
                    .foregroundStyle(RinklerColors.signalText)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(RinklerColors.signalTextFaint)
            }
            .padding(.horizontal, RinklerSpacing.md)
            .frame(height: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var aboutDivider: some View {
        Rectangle()
            .fill(RinklerColors.signalBorder)
            .frame(height: 1)
            .padding(.leading, RinklerSpacing.md + 22 + RinklerSpacing.md)
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "v\(v) (\(b))"
    }

    private func openContact() {
        guard let url = URL(string: "mailto:\(LegalContent.contactEmail)") else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - VPN Status

    private var vpnStatusSection: some View {
        VStack(spacing: RinklerSpacing.sm) {
            Image(systemName: vpnManager.vpnStatus == .connected ? "shield.fill" : "shield.slash.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundColor(vpnManager.vpnStatus == .connected ? .green : .gray)

            HStack(spacing: RinklerSpacing.sm) {
                Circle()
                    .fill(VPNManager.statusColor(for: vpnManager.vpnStatus))
                    .frame(width: 10, height: 10)
                Text(vpnManager.statusString)
                    .font(RinklerFonts.coolvetica(size: 18))
                    .foregroundStyle(RinklerColors.signalText)
            }
        }
    }

    // MARK: - VPN Toggle

    private var vpnToggleButton: some View {
        Button(action: { vpnManager.toggleVPN() }) {
            Text(vpnButtonTitle)
                .font(RinklerFonts.pupok(size: 24))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, RinklerSpacing.md)
                .background(vpnManager.vpnStatus == .connected ? Color.red : RinklerColors.skyBlue)
                .clipShape(RoundedRectangle(cornerRadius: RinklerSpacing.buttonCornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: RinklerSpacing.buttonCornerRadius)
                        .strokeBorder(Color.white, lineWidth: 1)
                )
        }
        .disabled(vpnManager.isPreparingProfile || strictMode.isActive)
    }

    private var vpnButtonTitle: String {
        if vpnManager.isPreparingProfile {
            return "PREPARING..."
        }
        return vpnManager.vpnStatus == .connected ? "STOP PROTECTION" : "START PROTECTION"
    }

    // MARK: - Permissions

    private var permissionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PERMISSIONS")
                .font(RinklerFonts.sans(12, .semibold))
                .foregroundStyle(RinklerColors.signalTextDim)

            HStack(spacing: RinklerSpacing.md) {
                Image(systemName: "hourglass")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(RinklerColors.signalBlue)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Screen Time access")
                        .font(RinklerFonts.sans(15, .medium))
                        .foregroundStyle(RinklerColors.signalText)
                    Text(screenTime.isAuthorized
                         ? "Granted — Rinkler can shield apps and show the block screen."
                         : "Lets Rinkler shield apps and show the block screen over them.")
                        .font(RinklerFonts.sans(12, .regular))
                        .foregroundStyle(RinklerColors.signalTextDim)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: RinklerSpacing.sm)
                if screenTime.isAuthorized {
                    Text("Granted")
                        .font(RinklerFonts.sans(13, .semibold))
                        .foregroundStyle(RinklerColors.signalSuccess)
                } else {
                    Button {
                        Task { await screenTime.requestAccess() }
                    } label: {
                        Text("Grant")
                            .font(RinklerFonts.sans(13, .semibold))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 16).frame(height: 34)
                            .background(RinklerColors.signalInk)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(RinklerSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RinklerColors.signalCard)
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(RinklerColors.signalBorder, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .onAppear { screenTime.refresh() }
    }

    // MARK: - Focus System

    private var focusSystemSection: some View {
        VStack(alignment: .leading, spacing: RinklerSpacing.sm) {
            Text("Your Focus System")
                .font(RinklerFonts.coolvetica(size: 18))
                .foregroundStyle(RinklerColors.signalText)

            if focusSystem.rules.isEmpty {
                Text("Nothing here yet. Run setup again and we'll build rules from your answers.")
                    .font(RinklerFonts.coolvetica(size: 13))
                    .foregroundStyle(RinklerColors.signalTextDim)
            } else {
                ForEach(focusSystem.rules) { rule in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(rule.name)
                                .font(RinklerFonts.coolvetica(size: 15))
                                .foregroundStyle(RinklerColors.signalText)
                            Text(rule.timeRangeLabel)
                                .font(RinklerFonts.mono(12, .regular))
                                .foregroundStyle(RinklerColors.signalTextDim)
                        }
                        Spacer()
                        Text(rule.difficulty.title)
                            .font(RinklerFonts.coolvetica(size: 11))
                            .foregroundColor(RinklerColors.signalBlue)
                    }
                }
            }

            Button(role: .destructive) {
                showResetOnboarding = true
            } label: {
                Text("Reset onboarding (testing)")
                    .font(RinklerFonts.coolvetica(size: 14))
                    .foregroundColor(RinklerColors.signalWarning)
            }
            .padding(.top, RinklerSpacing.xs)
            .disabled(strictMode.isActive)
        }
        .padding(RinklerSpacing.md)
        .background(RinklerColors.signalCard)
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(RinklerColors.signalBorder, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .alert("Reset onboarding?", isPresented: $showResetOnboarding) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                focusSystem.resetOnboarding()
                dismiss()
            }
        } message: {
            Text("Story-mode setup comes back next launch and your generated rules get wiped.")
        }
    }

    // MARK: - Commitment Mode

    private var commitmentSection: some View {
        VStack(alignment: .leading, spacing: RinklerSpacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Commitment mode")
                        .font(RinklerFonts.coolvetica(size: 18))
                        .foregroundStyle(RinklerColors.signalText)
                    Text("Turning protection off is the hard part now.")
                        .font(RinklerFonts.coolvetica(size: 13))
                        .foregroundStyle(RinklerColors.signalTextDim)
                }
                Spacer()
                Toggle("", isOn: $commitment.isEnabled)
                    .labelsHidden()
                    .disabled(strictMode.isActive)
            }

            if commitment.isEnabled {
                Divider().overlay(RinklerColors.signalBorder)

                Text("How long you wait before you can bail")
                    .font(RinklerFonts.coolvetica(size: 14))
                    .foregroundStyle(RinklerColors.signalTextDim)

                Picker("Cooldown", selection: $commitment.cooldownSeconds) {
                    ForEach(CommitmentStore.cooldownOptions, id: \.self) { seconds in
                        Text(CommitmentStore.label(forCooldown: seconds)).tag(seconds)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(strictMode.isActive)

                Text("When protection is on, stopping it asks you to wait out this pause and type \(CommitmentStore.unlockWord). iOS Settings can still switch the VPN off — this only adds friction inside Rinkler.")
                    .font(RinklerFonts.coolvetica(size: 12))
                    .foregroundStyle(RinklerColors.signalTextFaint)
                    .fixedSize(horizontal: false, vertical: true)

                if commitment.disablesToday > 0 {
                    Text("Bailed \(commitment.disablesToday)× today")
                        .font(RinklerFonts.coolvetica(size: 12))
                        .foregroundStyle(RinklerColors.signalWarning)
                }
            }
        }
        .padding(RinklerSpacing.md)
        .background(RinklerColors.signalCard)
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(RinklerColors.signalBorder, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Short-Video Filters

    private var shortVideoFiltersSection: some View {
        VStack(alignment: .leading, spacing: RinklerSpacing.sm) {
            Text("Short-video filters")
                .font(RinklerFonts.coolvetica(size: 18))
                .foregroundStyle(RinklerColors.signalText)

            filterToggleRow(title: "Instagram Reels", isOn: $blockInstagramShortVideo)
            filterToggleRow(title: "TikTok feed", isOn: $blockTikTokShortVideo)
        }
        .padding(RinklerSpacing.md)
        .background(RinklerColors.signalCard)
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(RinklerColors.signalBorder, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func filterToggleRow(title: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(title)
                .font(RinklerFonts.coolvetica(size: 16))
                .foregroundStyle(RinklerColors.signalTextDim)
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .disabled(strictMode.isActive)
        }
    }

    private var hasActiveShortVideoFilter: Bool {
        blockInstagramShortVideo || blockTikTokShortVideo
    }

    // MARK: - Domain Thresholds

    private var domainThresholdsSection: some View {
        VStack(spacing: RinklerSpacing.sm) {
            Text("Per-Domain Thresholds")
                .font(RinklerFonts.coolvetica(size: 16))
                .foregroundStyle(RinklerColors.signalTextDim)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(RinklerConstants.domainThresholdGroups.indices, id: \.self) { index in
                let group = RinklerConstants.domainThresholdGroups[index]
                VStack(alignment: .leading, spacing: RinklerSpacing.xs) {
                    Text(group.title)
                        .font(RinklerFonts.coolvetica(size: 14))
                        .foregroundStyle(RinklerColors.signalText)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ForEach(group.domains, id: \.self) { domain in
                        DomainThresholdRow(
                            domain: domain,
                            threshold: domainThresholds.binding(for: domain),
                            isLocked: strictMode.isActive
                        )
                    }
                }
            }
        }
        .padding(RinklerSpacing.md)
        .background(RinklerColors.signalCard)
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(RinklerColors.signalBorder, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - App Log

    private var appLogSection: some View {
        VStack(alignment: .leading, spacing: RinklerSpacing.xs) {
            Text("App Log")
                .font(RinklerFonts.coolvetica(size: 16))
                .foregroundStyle(RinklerColors.signalTextDim)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 1) {
                    ForEach(vpnManager.statusLog.reversed(), id: \.self) { line in
                        Text(line)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(RinklerColors.signalTextDim)
                    }
                }
            }
            .frame(maxHeight: 120)
            .padding(RinklerSpacing.sm)
            .background(Color.black.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - Extension Log

    private var extensionLogButton: some View {
        Button {
            vpnManager.refreshTunnelLog()
            showExtensionLog = true
        } label: {
            Text("Show Debug Extension Log")
                .font(RinklerFonts.coolvetica(size: 16))
                .foregroundStyle(RinklerColors.signalText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, RinklerSpacing.sm)
                .background(Color.white.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var extensionLogSheet: some View {
        NavigationView {
            ScrollView {
                Text(vpnManager.tunnelLog)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(RinklerColors.signalText)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .background(RinklerColors.signalBackground)
            .navigationTitle("Extension Log")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { showExtensionLog = false }
                }
                ToolbarItem(placement: .primaryAction) {
                    HStack {
                        Button("Copy") {
                            UIPasteboard.general.string = vpnManager.tunnelLog
                        }
                        Button("Refresh") { vpnManager.refreshTunnelLog() }
                    }
                }
            }
        }
        .preferredColorScheme(nil)
    }
}

// MARK: - Extension Log View (standalone route)

struct ExtensionLogView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var vpnManager: VPNManager

    var body: some View {
        ZStack {
            SignalBackground()

            ScrollView {
                Text(vpnManager.tunnelLog)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(RinklerColors.signalText)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: { BackArrowView() }
            }
            ToolbarItem(placement: .primaryAction) {
                HStack {
                    Button("Copy") {
                        UIPasteboard.general.string = vpnManager.tunnelLog
                    }
                    Button("Refresh") { vpnManager.refreshTunnelLog() }
                }
                .foregroundStyle(RinklerColors.signalText)
            }
        }
        .onAppear {
            vpnManager.refreshTunnelLog()
        }
    }
}
