import SwiftUI
import NetworkExtension

struct SettingsScreen: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var vpnManager: VPNManager
    @EnvironmentObject private var commitment: CommitmentStore
    @EnvironmentObject private var focusSystem: FocusSystemStore

    @State private var showResetOnboarding = false

    @AppStorage(RinklerConstants.blockInstagramShortVideoEnabledKey,
                store: UserDefaults(suiteName: RinklerConstants.appGroupID))
    private var blockInstagramShortVideo: Bool = true

    @AppStorage(RinklerConstants.blockTikTokShortVideoEnabledKey,
                store: UserDefaults(suiteName: RinklerConstants.appGroupID))
    private var blockTikTokShortVideo: Bool = true

    @StateObject private var domainThresholds = DomainThresholdsStore()
    @StateObject private var screenTime = ScreenTimeManager()

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

                    // Permissions the app needs (Screen Time access, etc.)
                    permissionsSection

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
                    .foregroundColor(.white)
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
        .disabled(vpnManager.isPreparingProfile)
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
                            .background(RinklerColors.signalText)
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
                .foregroundColor(.white)

            if focusSystem.rules.isEmpty {
                Text("No rules yet. Redo setup and we'll build them from your answers.")
                    .font(RinklerFonts.coolvetica(size: 13))
                    .foregroundColor(RinklerColors.white60)
            } else {
                ForEach(focusSystem.rules) { rule in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(rule.name)
                                .font(RinklerFonts.coolvetica(size: 15))
                                .foregroundColor(.white)
                            Text(rule.timeRangeLabel)
                                .font(RinklerFonts.mono(12, .regular))
                                .foregroundColor(RinklerColors.white60)
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
            Text("Story-mode setup will show again next launch and your generated rules will be cleared.")
        }
    }

    // MARK: - Commitment Mode

    private var commitmentSection: some View {
        VStack(alignment: .leading, spacing: RinklerSpacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Commitment mode")
                        .font(RinklerFonts.coolvetica(size: 18))
                        .foregroundColor(.white)
                    Text("Make turning protection OFF the hard part.")
                        .font(RinklerFonts.coolvetica(size: 13))
                        .foregroundColor(RinklerColors.white60)
                }
                Spacer()
                Toggle("", isOn: $commitment.isEnabled)
                    .labelsHidden()
            }

            if commitment.isEnabled {
                Divider().overlay(RinklerColors.hairline)

                Text("Cooldown before you can disable")
                    .font(RinklerFonts.coolvetica(size: 14))
                    .foregroundColor(RinklerColors.white60)

                Picker("Cooldown", selection: $commitment.cooldownSeconds) {
                    ForEach(CommitmentStore.cooldownOptions, id: \.self) { seconds in
                        Text(CommitmentStore.label(forCooldown: seconds)).tag(seconds)
                    }
                }
                .pickerStyle(.segmented)

                Text("When protection is on, stopping it asks you to wait out this pause and type \(CommitmentStore.unlockWord). iOS Settings can still switch the VPN off — this only adds friction inside Rinkler.")
                    .font(RinklerFonts.coolvetica(size: 12))
                    .foregroundColor(RinklerColors.white40)
                    .fixedSize(horizontal: false, vertical: true)

                if commitment.disablesToday > 0 {
                    Text("Disabled \(commitment.disablesToday)× today")
                        .font(RinklerFonts.coolvetica(size: 12))
                        .foregroundColor(RinklerColors.dawnGlow)
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
                .foregroundColor(.white)

            filterToggleRow(title: "Instagram video feed", isOn: $blockInstagramShortVideo)
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
                .foregroundColor(RinklerColors.white60)
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
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
                .foregroundColor(RinklerColors.white60)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(RinklerConstants.domainThresholdGroups.indices, id: \.self) { index in
                let group = RinklerConstants.domainThresholdGroups[index]
                VStack(alignment: .leading, spacing: RinklerSpacing.xs) {
                    Text(group.title)
                        .font(RinklerFonts.coolvetica(size: 14))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ForEach(group.domains, id: \.self) { domain in
                        DomainThresholdRow(
                            domain: domain,
                            threshold: domainThresholds.binding(for: domain)
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
                .foregroundColor(RinklerColors.white60)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 1) {
                    ForEach(vpnManager.statusLog.reversed(), id: \.self) { line in
                        Text(line)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(RinklerColors.white60)
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
                .foregroundColor(.white)
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
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .background(Color.black)
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
        .preferredColorScheme(.dark)
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
                    .foregroundColor(.white)
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
                .foregroundColor(.white)
            }
        }
        .onAppear {
            vpnManager.refreshTunnelLog()
        }
    }
}
