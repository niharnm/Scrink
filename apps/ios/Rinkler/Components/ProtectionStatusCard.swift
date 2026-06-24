import SwiftUI
import NetworkExtension

/// The single, unmistakable "is protection on?" surface.
///
/// One component, used in two places (Today dashboard top + Settings), so the
/// answer to "am I protected right now?" reads the same everywhere instead of
/// the three divergent renderings it had before.
///
/// - CONNECTED → a tinted/filled accent surface, filled shield, "Protected"
///   headline, and a quiet Stop control.
/// - OFF → a muted card, hollow shield, "Not protected", and a prominent Start
///   control.
///
/// The transition animates with a soft spring, and turning protection ON fires a
/// success haptic.
struct ProtectionStatusCard: View {
    let status: NEVPNStatus
    /// True while the VPN profile is being created/saved (disables the control).
    var isPreparing: Bool = false
    /// True when Strict Mode locks the control off.
    var isLocked: Bool = false
    let onToggle: () -> Void

    private var isConnected: Bool {
        status == .connected || status == .connecting || status == .reasserting
    }

    private var isBusy: Bool {
        isPreparing || status == .connecting || status == .disconnecting || status == .reasserting
    }

    private var accent: Color { RinklerColors.signalSuccess }

    private var headline: String {
        switch status {
        case .connected:      return "Protected"
        case .connecting,
             .reasserting:    return "Connecting…"
        case .disconnecting:  return "Stopping…"
        default:              return "Not protected"
        }
    }

    private var subtitle: String {
        isConnected
            ? "Best-effort feed, ad & tracker blocking is on. Some clips may slip through — hard-block whole apps via Shield."
            : "Turn it on for best-effort blocking of feeds, ads & trackers."
    }

    private var controlLabel: String {
        if isPreparing { return "Preparing…" }
        return isConnected ? "Stop" : "Start"
    }

    var body: some View {
        HStack(spacing: RinklerSpacing.md) {
            ZStack {
                Circle()
                    .fill(isConnected ? accent.opacity(0.18) : RinklerColors.signalCardRaised)
                    .frame(width: 48, height: 48)
                Image(systemName: isConnected ? "shield.lefthalf.filled" : "shield.slash")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(isConnected ? accent : RinklerColors.signalTextDim)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(headline)
                    .font(RinklerFonts.sans(19, .bold))
                    .foregroundStyle(RinklerColors.signalText)
                    .contentTransition(.opacity)
                Text(subtitle)
                    .font(RinklerFonts.sans(12, .regular))
                    .foregroundStyle(RinklerColors.signalTextDim)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: RinklerSpacing.sm)

            Button(action: onToggle) {
                Text(controlLabel)
                    .font(RinklerFonts.sans(15, .semibold))
                    .foregroundStyle(isConnected ? RinklerColors.signalText : RinklerColors.signalOnInk)
                    .padding(.horizontal, 20)
                    .frame(height: RinklerSpacing.compactControl)
                    .background(isConnected ? AnyView(RinklerColors.signalCardRaised) : AnyView(RinklerColors.signalInk))
                    .clipShape(Capsule())
                    // Floor the tappable area at 44pt even though the pill is 36.
                    .frame(minHeight: RinklerSpacing.minHitTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(isBusy || isLocked)
            .opacity(isBusy || isLocked ? 0.5 : 1)
        }
        .padding(RinklerSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isConnected ? AnyView(accent.opacity(0.12)) : AnyView(RinklerColors.signalCard))
        .overlay(
            RoundedRectangle(cornerRadius: RinklerSpacing.cardRadius, style: .continuous)
                .strokeBorder(isConnected ? accent.opacity(0.45) : RinklerColors.signalBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: RinklerSpacing.cardRadius, style: .continuous))
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isConnected)
        // Success buzz only the moment protection actually comes up (not when it
        // goes down) — `status == .connected` becoming true.
        .sensoryFeedback(trigger: status == .connected) { old, new in
            new && !old ? .success : nil
        }
    }
}

#Preview {
    ZStack {
        SignalBackground()
        VStack(spacing: 16) {
            ProtectionStatusCard(status: .connected, onToggle: {})
            ProtectionStatusCard(status: .disconnected, onToggle: {})
            ProtectionStatusCard(status: .connecting, onToggle: {})
        }
        .padding()
    }
}
