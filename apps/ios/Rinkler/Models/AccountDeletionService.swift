import Foundation
import Combine

/// Drives the two-step "request account deletion" flow:
///   1. send a one-time code to the user's email (reuses Supabase's OTP email)
///   2. verify that code, confirm it's the SAME account, then delete it
/// Re-verifying an emailed code proves it's really the owner — guards against an
/// accidental tap or someone with a borrowed, already-signed-in phone.
@MainActor
final class AccountDeletionService: ObservableObject {
    /// `.verifiedRetry`: the code checked out and identity is confirmed, but the
    /// delete call itself failed (e.g. flaky network) — we can retry the delete
    /// WITHOUT a fresh code, since the verified session is still valid.
    enum Phase: Equatable { case idle, sending, codeSent, deleting, verifiedRetry, done }

    @Published var phase: Phase = .idle
    @Published var errorMessage: String?

    var isBusy: Bool { phase == .sending || phase == .deleting }

    func sendCode(email: String) async {
        guard phase != .sending else { return }
        guard !email.isEmpty else {
            errorMessage = "No email on file for this account."
            return
        }
        phase = .sending
        errorMessage = nil
        do {
            // createUser:false — for deletion the email must already be ours;
            // never provision a phantom account here.
            try await SupabaseAuthClient.shared.sendMagicCode(email: email, createUser: false)
            phase = .codeSent
        } catch {
            errorMessage = "Couldn't send the code. Check your connection and try again."
            phase = .idle
        }
    }

    /// Verifies the emailed code, confirms identity, then deletes. Returns true
    /// once the local session is torn down (caller routes to a signed-out state).
    func confirmDeletion(email: String, code: String) async -> Bool {
        guard phase != .deleting else { return false }        // idempotency (no double-run)
        let cleaned = code.replacingOccurrences(of: " ", with: "")
        guard cleaned.count == 6, cleaned.allSatisfy(\.isNumber) else {
            errorMessage = "Enter the 6-digit code from your email."
            return false
        }
        phase = .deleting
        errorMessage = nil

        // Step 1 — re-verify identity via the emailed code.
        let priorUserID = SupabaseAuthClient.shared.loadSession()?.userID
        let verified: SupabaseAuthSession
        do {
            verified = try await SupabaseAuthClient.shared.verifyEmailOTP(email: email, token: cleaned)
        } catch {
            errorMessage = "That code didn't work. Double-check it, or send a new one."
            phase = .codeSent
            return false
        }

        // The verified account MUST be the one we were signed into — otherwise we
        // could delete a different (phantom) identity while the real one survives.
        guard let prior = priorUserID, prior == verified.userID else {
            SupabaseAuthClient.shared.clearLocalSession()
            errorMessage = "Couldn't confirm this is your account. Please sign in again."
            phase = .codeSent
            return false
        }

        // Step 2 — delete. Identity is confirmed; failures here are delete-stage.
        return await performDelete()
    }

    /// Retry just the delete using the already-verified session (no new code).
    func retryDelete() async -> Bool {
        guard phase == .verifiedRetry else { return false }
        phase = .deleting
        errorMessage = nil
        return await performDelete()
    }

    private func performDelete() async -> Bool {
        do {
            try await SupabaseAuthClient.shared.deleteCurrentUser()
        } catch {
            // Identity was confirmed but the delete didn't land. Keep the valid
            // session so the user can retry without a fresh code.
            errorMessage = "We confirmed it's you, but couldn't finish deleting. Check your connection and tap to try again."
            phase = .verifiedRetry
            return false
        }
        SupabaseAuthClient.shared.clearLocalSession()
        phase = .done
        return true
    }
}
