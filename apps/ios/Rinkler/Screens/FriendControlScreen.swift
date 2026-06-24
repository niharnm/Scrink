import SwiftUI

/// Owner UI for friend remote control: grant a friend a time-boxed window via a
/// short code; they set your limits from rinkler.app/friend; you can revoke.
struct FriendControlScreen: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var friend: FriendControlStore

    @State private var windowHours = 4
    private let options = [1, 4, 8, 24]

    var body: some View {
        ZStack {
            SignalBackground()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: RinklerSpacing.lg) {
                    header

                    if !friend.isSignedIn {
                        signInPrompt
                    } else if friend.isControlled {
                        controlledCard
                    } else if friend.hasPendingCode {
                        codeCard
                    } else {
                        setupCard
                    }

                    caveat
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
        .task { await friend.refresh() }
        .alert("Heads up", isPresented: Binding(get: { friend.error != nil },
                                                set: { _ in friend.error = nil })) {
            Button("OK", role: .cancel) {}
        } message: { Text(friend.error ?? "") }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("FRIEND CONTROL")
                .font(RinklerFonts.sans(13, .semibold)).tracking(2)
                .foregroundStyle(RinklerColors.signalTextDim)
            Text("Hand a friend the keys")
                .font(RinklerFonts.sans(28, .bold))
                .foregroundStyle(RinklerColors.signalText)
            Text("Give someone you trust a code. For the window you pick, they tighten your limits from their phone, and you can't loosen them yourself.")
                .font(RinklerFonts.sans(15, .regular))
                .foregroundStyle(RinklerColors.signalTextDim)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var setupCard: some View {
        VStack(alignment: .leading, spacing: RinklerSpacing.md) {
            Text("HOW LONG DO THEY GET")
                .font(RinklerFonts.sans(12, .semibold))
                .foregroundStyle(RinklerColors.signalTextDim)
            HStack(spacing: 8) {
                ForEach(options, id: \.self) { h in
                    Button { windowHours = h } label: {
                        Text(h >= 24 ? "1 day" : "\(h)h")
                            .font(RinklerFonts.mono(15, .medium))
                            .foregroundStyle(windowHours == h ? RinklerColors.signalOnInk : RinklerColors.signalText)
                            .frame(maxWidth: .infinity).frame(height: 44)
                            .background(windowHours == h ? AnyView(RinklerColors.signalInk) : AnyView(RinklerColors.signalCard))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            Button { Task { await friend.generateCode(windowHours: windowHours) } } label: {
                HStack(spacing: 8) {
                    if friend.busy { ProgressView().tint(RinklerColors.signalOnInk) }
                    Text(friend.busy ? "Making a code…" : "Make a code")
                        .font(RinklerFonts.sans(18, .semibold))
                }
                .foregroundStyle(RinklerColors.signalOnInk)
                .frame(maxWidth: .infinity).frame(height: 54)
                .background(RinklerColors.signalInk)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(friend.busy)
        }
        .padding(RinklerSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .signalCard(cornerRadius: 20)
    }

    private var codeCard: some View {
        VStack(spacing: RinklerSpacing.md) {
            Text("YOUR CODE")
                .font(RinklerFonts.sans(12, .semibold)).tracking(2)
                .foregroundStyle(RinklerColors.signalTextDim)
            Text(spaced(friend.pairing?.code ?? "------"))
                .font(RinklerFonts.mono(40, .medium))
                .foregroundStyle(RinklerColors.signalText)
            Text("Have your friend open rinkler.app/friend and punch this in within 15 minutes. They'll get \(friend.windowRemainingLabel.isEmpty ? "the window" : "control until the window ends").")
                .font(RinklerFonts.sans(13, .regular))
                .foregroundStyle(RinklerColors.signalTextDim)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Button { Task { await friend.revoke() } } label: {
                Text("Cancel this code")
                    .font(RinklerFonts.sans(14, .semibold))
                    .foregroundStyle(RinklerColors.signalWarning)
            }
            .buttonStyle(.plain)
        }
        .padding(RinklerSpacing.lg)
        .frame(maxWidth: .infinity)
        .signalCard(cornerRadius: 20)
    }

    private var controlledCard: some View {
        VStack(alignment: .leading, spacing: RinklerSpacing.md) {
            HStack(spacing: 8) {
                Image(systemName: "person.fill.checkmark").foregroundStyle(RinklerColors.signalBlue)
                Text("A friend's running your limits")
                    .font(RinklerFonts.sans(17, .semibold))
                    .foregroundStyle(RinklerColors.signalText)
            }
            RinklerStatRow(stats: [
                ("Window", friend.windowRemainingLabel.replacingOccurrences(of: " left", with: ""), nil),
                ("Limits added", "\(friend.appliedCount)", RinklerColors.signalBlue),
            ])
            Text("They keep tightening until the window's up. You can still end it early, but they'll see you did.")
                .font(RinklerFonts.sans(12, .regular))
                .foregroundStyle(RinklerColors.signalTextDim)
                .fixedSize(horizontal: false, vertical: true)
            Button(role: .destructive) { Task { await friend.revoke() } } label: {
                Text("End their access")
                    .font(RinklerFonts.sans(15, .semibold))
                    .foregroundStyle(RinklerColors.signalWarning)
                    .frame(maxWidth: .infinity).frame(height: 48)
                    .background(RinklerColors.signalCard)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(RinklerSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .signalCard(cornerRadius: 20)
    }

    private var signInPrompt: some View {
        Text("Sign in first — friend control syncs through your account so your friend's changes reach this phone.")
            .font(RinklerFonts.sans(14, .regular))
            .foregroundStyle(RinklerColors.signalTextDim)
            .fixedSize(horizontal: false, vertical: true)
            .padding(RinklerSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .signalCard(cornerRadius: 16)
    }

    private var caveat: some View {
        Text("A friend can only ADD blocks, never loosen them, and only until the window you set ends. Codes expire in 15 minutes if unused.")
            .font(.system(size: 12))
            .foregroundStyle(RinklerColors.signalTextDim)
            .fixedSize(horizontal: false, vertical: true)
            .padding(RinklerSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RinklerColors.signalBlue.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func spaced(_ s: String) -> String { s.map(String.init).joined(separator: " ") }
}
