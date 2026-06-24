import SwiftUI
#if canImport(FamilyControls)
import FamilyControls
#endif

/// Arms Strict Mode. Friction lives here (you confirm hard to turn it ON) because
/// there is deliberately no in-app way to turn it OFF before the window ends.
struct StrictModeSetupScreen: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var strictMode: StrictModeStore
    @EnvironmentObject private var screenTime: ScreenTimeManager

    @State private var hours: Int = 1
    @State private var lockAppRemoval = true
    @State private var confirmText = ""
    @State private var showPicker = false
    #if canImport(FamilyControls)
    @State private var selection = FamilyActivitySelection()
    #endif

    private let options = [1, 2, 4, 8]
    private let confirmWord = "LOCK"

    private var canArm: Bool {
        confirmText.trimmingCharacters(in: .whitespaces).uppercased() == confirmWord
    }

    var body: some View {
        ZStack {
            SignalBackground()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: RinklerSpacing.lg) {
                    header

                    group("HOW LONG") {
                        HStack(spacing: 8) {
                            ForEach(options, id: \.self) { h in
                                Button { hours = h } label: {
                                    Text("\(h)h")
                                        .font(RinklerFonts.mono(15, .medium))
                                        .foregroundStyle(hours == h ? RinklerColors.signalOnInk : RinklerColors.signalText)
                                        .frame(maxWidth: .infinity).frame(height: 46)
                                        .background(hours == h ? AnyView(RinklerColors.signalInk) : AnyView(RinklerColors.signalCard))
                                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(RinklerColors.signalBorder, lineWidth: hours == h ? 0 : 1))
                                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    group("TOTAL LOCKDOWN") {
                        VStack(alignment: .leading, spacing: 8) {
                            // App-removal blocking is enforced by the Family Controls
                            // shield, which only does anything once Screen Time access
                            // is granted. Until then the toggle is a no-op, so don't
                            // present it as an armable capability — show how to enable it.
                            if screenTime.isAuthorized {
                                Toggle(isOn: $lockAppRemoval) {
                                    Text("Block deleting apps")
                                        .font(RinklerFonts.sans(15, .medium))
                                        .foregroundStyle(RinklerColors.signalText)
                                }
                                .tint(RinklerColors.signalBlue)
                                Text("Stops you deleting any app on your phone — Rinkler included — until the window's up.")
                                    .font(RinklerFonts.sans(12, .regular))
                                    .foregroundStyle(RinklerColors.signalTextDim)
                                    .fixedSize(horizontal: false, vertical: true)
                            } else {
                                Text("Blocking app deletion needs Screen Time access. Until you grant it, Strict Mode can't stop you deleting apps — it only locks Rinkler's own controls and keeps the feed filter on.")
                                    .font(RinklerFonts.sans(12, .regular))
                                    .foregroundStyle(RinklerColors.signalTextDim)
                                    .fixedSize(horizontal: false, vertical: true)
                                Button { Task { await screenTime.requestAccess() } } label: {
                                    Text("Grant Screen Time access")
                                        .font(RinklerFonts.sans(14, .semibold))
                                        .foregroundStyle(RinklerColors.signalBlue)
                                }
                            }
                        }
                        .padding(RinklerSpacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .signalCard(cornerRadius: 16)
                    }

                    appLockSection

                    caveat

                    group("TYPE \(confirmWord) TO ARM") {
                        TextField("", text: $confirmText)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .font(RinklerFonts.mono(20, .medium))
                            .foregroundStyle(RinklerColors.signalText)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 14)
                            .signalCard(cornerRadius: 14)
                    }

                    Button(action: arm) {
                        Text("Arm it")
                            .font(RinklerFonts.sans(18, .semibold))
                            .foregroundStyle(RinklerColors.signalOnInk)
                            .frame(maxWidth: .infinity).frame(height: 56)
                            .background(canArm ? RinklerColors.signalInk : RinklerColors.signalCardRaised)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(!canArm)
                }
                .padding(RinklerSpacing.lg)
                .padding(.bottom, 60)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: { BackArrowView() }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("STRICT MODE")
                .font(RinklerFonts.sans(13, .semibold))
                .foregroundStyle(RinklerColors.signalTextDim)
            Text("Lock it and actually mean it")
                .font(RinklerFonts.sans(28, .bold))
                .foregroundStyle(RinklerColors.signalText)
            Text("Once it's armed, there's no lowering or killing your limits from inside Rinkler till the window ends. No cooldown, no magic word — it just holds.")
                .font(RinklerFonts.sans(15, .regular))
                .foregroundStyle(RinklerColors.signalTextDim)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var appLockSection: some View {
        group("APPS TO LOCK") {
            if screenTime.isAuthorized {
                #if canImport(FamilyControls)
                Button { showPicker = true } label: {
                    HStack {
                        Text(selection.applicationTokens.isEmpty ? "Pick apps to block" : "\(selection.applicationTokens.count) app(s) selected")
                            .font(RinklerFonts.sans(15, .medium))
                            .foregroundStyle(RinklerColors.signalText)
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(RinklerColors.signalTextFaint)
                    }
                    .padding(RinklerSpacing.md)
                    .signalCard(cornerRadius: 14)
                }
                .buttonStyle(.plain)
                .familyActivityPicker(isPresented: $showPicker, selection: $selection)
                .onChange(of: selection) { _, newValue in persistSelection(newValue) }
                #endif
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Right now Strict Mode locks Rinkler's own controls and keeps the feed filter on. Blocking app launches and app deletion turns on once you grant Screen Time access.")
                        .font(RinklerFonts.sans(13, .regular))
                        .foregroundStyle(RinklerColors.signalTextDim)
                        .fixedSize(horizontal: false, vertical: true)
                    Button { Task { await screenTime.requestAccess() } } label: {
                        Text("Grant Screen Time access")
                            .font(RinklerFonts.sans(14, .semibold))
                            .foregroundStyle(RinklerColors.signalBlue)
                    }
                }
                .padding(RinklerSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .signalCard(cornerRadius: 14)
            }
        }
    }

    private var caveat: some View {
        Text("The only way out before the timer ends is iOS Settings → Screen Time. That's the one true bypass — we don't hide it.")
            .font(.system(size: 12))
            .foregroundStyle(RinklerColors.signalTextDim)
            .fixedSize(horizontal: false, vertical: true)
            .padding(RinklerSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RinklerColors.signalWarning.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func group<C: View>(_ title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(RinklerFonts.sans(12, .semibold))
                .foregroundStyle(RinklerColors.signalTextDim)
            content()
        }
    }

    private func persistSelection(_ sel: Any) {
        #if canImport(FamilyControls)
        if let s = sel as? FamilyActivitySelection, let data = try? JSONEncoder().encode(s) {
            UserDefaults(suiteName: RinklerConstants.appGroupID)?
                .set(data, forKey: RinklerConstants.strictModeAppSelectionKey)
        }
        #endif
    }

    private func arm() {
        strictMode.arm(duration: TimeInterval(hours * 3600), lockAppRemoval: lockAppRemoval)
        dismiss()
    }
}
