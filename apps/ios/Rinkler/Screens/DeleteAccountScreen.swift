import SwiftUI

/// Step 2 of account deletion: a code is emailed to the user (reusing Supabase
/// OTP); they type it here to confirm, then the account is permanently deleted.
/// Reached only after the one-time confirmation alert in Settings.
struct DeleteAccountScreen: View {
    let email: String
    var onDeleted: () -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var service = AccountDeletionService()
    @State private var code = ""
    @FocusState private var codeFocused: Bool
    @State private var resendSeconds = 0

    private var cleanedCode: String { code.replacingOccurrences(of: " ", with: "") }

    private var canSubmit: Bool {
        if service.phase == .verifiedRetry { return true }
        return cleanedCode.count == 6 && !service.isBusy
    }

    var body: some View {
        ZStack {
            SignalBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: RinklerSpacing.lg) {
                    header

                    if service.phase == .verifiedRetry {
                        statusLine("Identity confirmed. Finishing up…", spinner: false)
                    } else if service.phase == .sending {
                        statusLine("Sending a code to \(email)…", spinner: true)
                    } else {
                        VStack(alignment: .leading, spacing: RinklerSpacing.sm) {
                            Text("Enter the code we emailed to")
                                .font(RinklerFonts.sans(13, .regular))
                                .foregroundStyle(RinklerColors.signalTextDim)
                            Text(email)
                                .font(RinklerFonts.sans(14, .semibold))
                                .foregroundStyle(RinklerColors.signalText)
                            codeField
                        }
                    }

                    if let error = service.errorMessage {
                        Text(error)
                            .font(RinklerFonts.sans(13, .regular))
                            .foregroundStyle(RinklerColors.signalDanger)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    deleteButton

                    if service.phase != .verifiedRetry {
                        Button {
                            Task { code = ""; await sendAndCooldown() }
                        } label: {
                            Text(resendLabel)
                                .font(RinklerFonts.sans(14, .medium))
                                .foregroundStyle(resendSeconds > 0 || service.isBusy
                                                 ? RinklerColors.signalTextFaint : RinklerColors.signalBlue)
                        }
                        .buttonStyle(.plain)
                        .disabled(service.isBusy || resendSeconds > 0)
                    }

                    Spacer(minLength: 0)
                }
                .padding(RinklerSpacing.lg)
            }
        }
        .navigationTitle("Delete account")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if service.phase == .idle { await sendAndCooldown() }
            codeFocused = true
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            if resendSeconds > 0 { resendSeconds -= 1 }
        }
    }

    private func sendAndCooldown() async {
        await service.sendCode(email: email)
        if service.phase == .codeSent { resendSeconds = 30 }
    }

    private var resendLabel: String {
        if service.isBusy { return "Working…" }
        if resendSeconds > 0 { return "Resend in \(resendSeconds)s" }
        return "Resend code"
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: RinklerSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(RinklerColors.signalDanger)
            Text("This deletes your account for good")
                .font(RinklerFonts.sans(20, .bold))
                .foregroundStyle(RinklerColors.signalText)
            Text("Your account and everything tied to it — rules, streaks, history — get wiped from our servers and can't be brought back. Confirm with the code we just emailed you.")
                .font(RinklerFonts.sans(14, .regular))
                .foregroundStyle(RinklerColors.signalTextDim)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func statusLine(_ text: String, spinner: Bool) -> some View {
        HStack(spacing: RinklerSpacing.sm) {
            if spinner { ProgressView().tint(RinklerColors.signalTextDim) }
            Text(text)
                .font(RinklerFonts.sans(14, .regular))
                .foregroundStyle(RinklerColors.signalTextDim)
        }
    }

    private var codeField: some View {
        TextField("", text: $code, prompt: Text("000000").foregroundStyle(RinklerColors.signalTextFaint))
            .keyboardType(.numberPad)
            .textContentType(.oneTimeCode)
            .multilineTextAlignment(.center)
            .font(RinklerFonts.mono(26, .medium))
            .foregroundStyle(RinklerColors.signalText)
            .focused($codeFocused)
            .onChange(of: code) { _, newValue in
                let digits = newValue.filter(\.isNumber)
                if digits.count <= 6 {
                    code = digits.count > 3
                        ? "\(digits.prefix(3)) \(digits.dropFirst(3))"
                        : digits
                } else {
                    code = "\(digits.prefix(3)) \(digits.dropFirst(3).prefix(3))"
                }
            }
            .padding(14)
            .background(RinklerColors.signalCard)
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(RinklerColors.signalBorder, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var deleteLabel: String {
        if service.phase == .deleting { return "Deleting…" }
        if service.phase == .verifiedRetry { return "Try deleting again" }
        return "Delete my account"
    }

    private var deleteButton: some View {
        Button {
            codeFocused = false
            Task {
                let ok = service.phase == .verifiedRetry
                    ? await service.retryDelete()
                    : await service.confirmDeletion(email: email, code: code)
                if ok { onDeleted() }
            }
        } label: {
            HStack(spacing: 8) {
                if service.phase == .deleting {
                    ProgressView().tint(RinklerColors.signalOnInk)
                }
                Text(deleteLabel)
                    .font(RinklerFonts.sans(16, .semibold))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity).frame(height: 52)
            .background(canSubmit ? RinklerColors.signalDanger : RinklerColors.signalDanger.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!canSubmit)
    }
}
