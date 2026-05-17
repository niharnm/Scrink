import SwiftUI
import NetworkExtension

struct SettingsScreen: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var vpnManager: VPNManager

    @AppStorage(BubbleConstants.blockInstagramShortVideoEnabledKey,
                store: UserDefaults(suiteName: BubbleConstants.appGroupID))
    private var blockInstagramShortVideo: Bool = true

    @AppStorage(BubbleConstants.blockTikTokShortVideoEnabledKey,
                store: UserDefaults(suiteName: BubbleConstants.appGroupID))
    private var blockTikTokShortVideo: Bool = true

    @StateObject private var domainThresholds = DomainThresholdsStore()

    @State private var showExtensionLog = false

    var body: some View {
        ZStack {
            SkyBackgroundView()

            ScrollView {
                VStack(spacing: BubbleSpacing.lg) {
                    // VPN Status Header
                    vpnStatusSection

                    // VPN Toggle Button
                    vpnToggleButton

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
                .padding(.horizontal, BubbleSpacing.lg)
                .padding(.top, BubbleSpacing.xl)
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
        VStack(spacing: BubbleSpacing.sm) {
            Image(systemName: vpnManager.vpnStatus == .connected ? "shield.fill" : "shield.slash.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundColor(vpnManager.vpnStatus == .connected ? .green : .gray)

            HStack(spacing: BubbleSpacing.sm) {
                Circle()
                    .fill(VPNManager.statusColor(for: vpnManager.vpnStatus))
                    .frame(width: 10, height: 10)
                Text(vpnManager.statusString)
                    .font(BubbleFonts.coolvetica(size: 18))
                    .foregroundColor(.white)
            }
        }
    }

    // MARK: - VPN Toggle

    private var vpnToggleButton: some View {
        Button(action: { vpnManager.toggleVPN() }) {
            Text(vpnButtonTitle)
                .font(BubbleFonts.pupok(size: 24))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, BubbleSpacing.md)
                .background(vpnManager.vpnStatus == .connected ? Color.red : BubbleColors.skyBlue)
                .clipShape(RoundedRectangle(cornerRadius: BubbleSpacing.buttonCornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: BubbleSpacing.buttonCornerRadius)
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

    // MARK: - Short-Video Filters

    private var shortVideoFiltersSection: some View {
        VStack(alignment: .leading, spacing: BubbleSpacing.sm) {
            Text("Short-video filters")
                .font(BubbleFonts.coolvetica(size: 18))
                .foregroundColor(.white)

            filterToggleRow(title: "Instagram video feed", isOn: $blockInstagramShortVideo)
            filterToggleRow(title: "TikTok feed", isOn: $blockTikTokShortVideo)
        }
        .padding(BubbleSpacing.md)
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func filterToggleRow(title: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(title)
                .font(BubbleFonts.coolvetica(size: 16))
                .foregroundColor(BubbleColors.white60)
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
        VStack(spacing: BubbleSpacing.sm) {
            Text("Per-Domain Thresholds")
                .font(BubbleFonts.coolvetica(size: 16))
                .foregroundColor(BubbleColors.white60)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(BubbleConstants.domainThresholdGroups.indices, id: \.self) { index in
                let group = BubbleConstants.domainThresholdGroups[index]
                VStack(alignment: .leading, spacing: BubbleSpacing.xs) {
                    Text(group.title)
                        .font(BubbleFonts.coolvetica(size: 14))
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
        .padding(BubbleSpacing.md)
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - App Log

    private var appLogSection: some View {
        VStack(alignment: .leading, spacing: BubbleSpacing.xs) {
            Text("App Log")
                .font(BubbleFonts.coolvetica(size: 16))
                .foregroundColor(BubbleColors.white60)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 1) {
                    ForEach(vpnManager.statusLog.reversed(), id: \.self) { line in
                        Text(line)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(BubbleColors.white60)
                    }
                }
            }
            .frame(maxHeight: 120)
            .padding(BubbleSpacing.sm)
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
                .font(BubbleFonts.coolvetica(size: 16))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, BubbleSpacing.sm)
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
            SkyBackgroundView()

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
