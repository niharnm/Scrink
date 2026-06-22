import SwiftUI
import Combine

// MARK: - Store

/// Commitment Mode makes turning protection *off* the high-friction action.
///
/// Rinkler's honest position (this is the part that sets it apart from a "Deep
/// Focus" hard wall): a local network filter can always be disabled in iOS
/// Settings, so we don't pretend to be unbreakable. Instead we add real friction
/// to the in-app Stop path — a cooldown you wait out plus a typed confirmation —
/// and we keep an accountability receipt every time protection is disabled while
/// committed. The inevitable bypass becomes visible self-data instead of a
/// silent slip.
@MainActor
final class CommitmentStore: ObservableObject {
    @Published var isEnabled: Bool { didSet { defaults?.set(isEnabled, forKey: Keys.enabled) } }
    @Published var cooldownSeconds: Int { didSet { defaults?.set(cooldownSeconds, forKey: Keys.cooldown) } }
    @Published private(set) var disableReceipts: [Date] = []

    /// Cooldown choices offered in Settings (seconds): 30s, 2 min, 10 min.
    static let cooldownOptions = [30, 120, 600]
    static let unlockWord = "STOP"

    private let defaults = UserDefaults(suiteName: RinklerConstants.appGroupID)

    private enum Keys {
        static let enabled = "commitmentModeEnabled"
        static let cooldown = "commitmentCooldownSeconds"
        static let receipts = "commitmentDisableReceipts"
    }

    init() {
        let d = UserDefaults(suiteName: RinklerConstants.appGroupID)
        // didSet does not fire for initial assignment in init, so this does not
        // redundantly write back the values we just read.
        isEnabled = d?.bool(forKey: Keys.enabled) ?? false
        cooldownSeconds = (d?.object(forKey: Keys.cooldown) as? Int) ?? 120
        loadReceipts()
    }

    /// Records that protection was disabled while committed.
    func recordDisable() {
        disableReceipts.append(Date())
        if disableReceipts.count > 100 {
            disableReceipts.removeFirst(disableReceipts.count - 100)
        }
        if let data = try? JSONEncoder().encode(disableReceipts) {
            defaults?.set(data, forKey: Keys.receipts)
        }
    }

    var disablesToday: Int {
        disableReceipts.filter { Calendar.current.isDateInToday($0) }.count
    }

    var lastDisable: Date? { disableReceipts.last }

    var cooldownLabel: String { Self.label(forCooldown: cooldownSeconds) }

    static func label(forCooldown seconds: Int) -> String {
        seconds < 60 ? "\(seconds)s" : "\(seconds / 60) min"
    }

    private func loadReceipts() {
        guard let data = defaults?.data(forKey: Keys.receipts),
              let decoded = try? JSONDecoder().decode([Date].self, from: data) else { return }
        disableReceipts = decoded
    }
}

// MARK: - Unlock friction sheet

/// The friction gate shown when a committed user tries to stop protection. They
/// must wait out a cooldown and type the unlock word. Honest about the fact that
/// iOS Settings can still disable the VPN — this governs only the in-app path.
struct CommitmentUnlockSheet: View {
    let cooldownSeconds: Int
    var onConfirm: () -> Void
    var onCancel: () -> Void

    @State private var remaining: Int
    @State private var typed: String = ""
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(cooldownSeconds: Int, onConfirm: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.cooldownSeconds = cooldownSeconds
        self.onConfirm = onConfirm
        self.onCancel = onCancel
        _remaining = State(initialValue: cooldownSeconds)
    }

    private var cooldownDone: Bool { remaining <= 0 }
    private var wordMatches: Bool {
        typed.trimmingCharacters(in: .whitespaces).uppercased() == CommitmentStore.unlockWord
    }
    private var canDisable: Bool { cooldownDone && wordMatches }

    /// Cooldown fraction (0→1) so the ring fills as the wait elapses — the ring
    /// *is* the timer.
    private var cooldownFraction: Double {
        cooldownDone ? 1 : 1 - Double(remaining) / Double(max(cooldownSeconds, 1))
    }

    var body: some View {
        ZStack {
            SignalBackground(intensity: 1.15)

            VStack(spacing: RinklerSpacing.lg) {
                Spacer()

                // Hero ring doubles as the cooldown gauge.
                SignalRing(progress: max(cooldownFraction, 0.04), lineWidth: 10) {
                    Image(systemName: cooldownDone ? "lock.open.fill" : "lock.fill")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(RinklerColors.signalBlue)
                }
                .frame(width: 148, height: 148)

                VStack(spacing: 10) {
                    Text("Sit with the urge.")
                        .font(RinklerFonts.sans(28, .bold))
                        .foregroundStyle(RinklerColors.signalText)
                    Text("You armed protection on purpose. Give it a moment before you turn it off — the urge usually passes.")
                        .font(RinklerFonts.sans(15, .regular))
                        .foregroundStyle(RinklerColors.signalTextDim)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, RinklerSpacing.lg)
                }

                if !cooldownDone {
                    VStack(spacing: 4) {
                        Text(timeString(remaining))
                            .font(RinklerFonts.mono(52, .medium))
                            .foregroundStyle(RinklerColors.signalText)
                            .contentTransition(.numericText())
                        Text("until you can turn it off")
                            .font(RinklerFonts.sans(12, .medium))
                            .foregroundStyle(RinklerColors.signalTextDim)
                    }
                    .padding(.vertical, RinklerSpacing.lg)
                    .frame(maxWidth: .infinity)
                    .signalCard(cornerRadius: 20)
                    .padding(.horizontal, RinklerSpacing.lg)
                } else {
                    VStack(spacing: RinklerSpacing.sm) {
                        Text("Type \(CommitmentStore.unlockWord) to confirm")
                            .font(RinklerFonts.sans(12, .medium))
                            .foregroundStyle(RinklerColors.signalTextDim)
                        TextField("", text: $typed)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .multilineTextAlignment(.center)
                            .font(RinklerFonts.mono(22, .medium))
                            .foregroundStyle(RinklerColors.signalText)
                            .padding(.vertical, 14)
                            .signalCard(cornerRadius: 14)
                    }
                    .padding(.horizontal, RinklerSpacing.xl)
                }

                Spacer()

                // The healthy choice is the prominent one.
                Button(action: onCancel) {
                    Text("Stay protected")
                        .font(RinklerFonts.sans(18, .semibold))
                        .foregroundStyle(RinklerColors.signalOnInk)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(RinklerColors.signalInk)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, RinklerSpacing.lg)

                // Turning off is the quiet, high-friction action.
                Button(action: onConfirm) {
                    Text("Turn off anyway")
                        .font(RinklerFonts.sans(15, .medium))
                        .foregroundStyle(canDisable ? RinklerColors.signalWarning : RinklerColors.signalTextDim.opacity(0.55))
                }
                .disabled(!canDisable)

                Text("iOS Settings → VPN can still switch Rinkler off. Commitment Mode only adds friction inside the app — it can't override the system.")
                    .font(.system(size: 11))
                    .foregroundStyle(RinklerColors.signalTextDim.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, RinklerSpacing.lg)
                    .padding(.bottom, RinklerSpacing.md)
            }
        }
        .onReceive(timer) { _ in
            if remaining > 0 { remaining -= 1 }
        }
        .interactiveDismissDisabled(true)
    }

    private func timeString(_ seconds: Int) -> String {
        seconds >= 60 ? String(format: "%d:%02d", seconds / 60, seconds % 60) : "\(seconds)"
    }
}
