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

    var body: some View {
        ZStack {
            RinklerColors.livingGradient(clarity: 0.2).ignoresSafeArea()

            VStack(spacing: RinklerSpacing.lg) {
                Spacer()

                Image(systemName: "lock.shield")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(RinklerColors.auroraCyan)

                Text("You're locked in")
                    .font(RinklerFonts.coolvetica(size: 26))
                    .foregroundStyle(.white)

                Text("You turned protection on with Commitment Mode. Sit with the urge for a moment before you turn it off.")
                    .font(RinklerFonts.caption)
                    .foregroundStyle(RinklerColors.white60)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, RinklerSpacing.lg)

                if !cooldownDone {
                    Text(timeString(remaining))
                        .font(RinklerFonts.coolvetica(size: 48))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                    Text("until you can disable")
                        .font(RinklerFonts.caption)
                        .foregroundStyle(RinklerColors.white40)
                } else {
                    VStack(spacing: RinklerSpacing.sm) {
                        Text("Type \(CommitmentStore.unlockWord) to confirm")
                            .font(RinklerFonts.caption)
                            .foregroundStyle(RinklerColors.white60)
                        TextField("", text: $typed)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .multilineTextAlignment(.center)
                            .font(RinklerFonts.coolvetica(size: 22))
                            .foregroundStyle(.white)
                            .padding(.vertical, RinklerSpacing.sm)
                            .background(RinklerColors.surfaceRaised)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .padding(.horizontal, RinklerSpacing.xl)
                    }
                }

                Spacer()

                Button(action: onConfirm) {
                    Text("Disable protection")
                        .font(RinklerFonts.coolvetica(size: 17))
                        .foregroundStyle(canDisable ? Color.black.opacity(0.85) : RinklerColors.white40)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(canDisable ? RinklerColors.dawnGlow : RinklerColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .disabled(!canDisable)
                .padding(.horizontal, RinklerSpacing.lg)

                Button(action: onCancel) {
                    Text("Stay locked in")
                        .font(RinklerFonts.coolvetica(size: 16))
                        .foregroundStyle(RinklerColors.auroraCyan)
                }

                Text("Heads up: iOS Settings → VPN can still switch Rinkler off. Commitment Mode only adds friction inside the app — it can't override the system.")
                    .font(.system(size: 11))
                    .foregroundStyle(RinklerColors.white30)
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
