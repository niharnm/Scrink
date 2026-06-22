"use client";

import { useActionState, useEffect, useState, CSSProperties } from "react";
import Link from "next/link";
import { requestEmailCode, verifyEmailCode } from "./actions";
import { createClient } from "@/lib/supabase/client";
import { signal } from "@/lib/signal";

export default function LoginPage() {
  const [requestState, requestAction, requestPending] = useActionState(requestEmailCode, null);
  const [verifyState, verifyAction, verifyPending] = useActionState(verifyEmailCode, null);
  const [codeInput, setCodeInput] = useState("");
  const [callbackError, setCallbackError] = useState(false);
  const [oauthBusy, setOauthBusy] = useState<"google" | "apple" | null>(null);
  const [oauthError, setOauthError] = useState<string | null>(null);

  // Same Supabase backend as the iOS app, so signing in here with Apple/Google
  // lands on the same account — and your phone's data shows up in the dashboard.
  async function signInWith(provider: "google" | "apple") {
    setOauthError(null);
    setOauthBusy(provider);
    try {
      const supabase = createClient();
      const { error } = await supabase.auth.signInWithOAuth({
        provider,
        options: { redirectTo: `${window.location.origin}/auth/callback` },
      });
      if (error) {
        setOauthError(error.message);
        setOauthBusy(null);
      }
      // On success the browser redirects to the provider; nothing else to do.
    } catch (e) {
      setOauthError(e instanceof Error ? e.message : "Sign-in failed. Try again.");
      setOauthBusy(null);
    }
  }

  const state = verifyState || requestState;
  const email = state?.email || "";
  const shouldEnterCode = state?.step === "code";
  const isPending = requestPending || verifyPending;
  const statusMessage = state && "message" in state ? state.message : null;
  useEffect(() => {
    setCallbackError(new URLSearchParams(window.location.search).has("error"));
  }, []);

  const containerStyle: CSSProperties = {
    display: "flex",
    flexDirection: "column",
    alignItems: "center",
    justifyContent: "center",
    minHeight: "100vh",
    padding: 24,
    background: signal.bg,
    fontFamily: signal.sans,
    position: "relative",
    overflow: "hidden",
  };

  const glow: CSSProperties = {
    position: "absolute",
    top: "-30%",
    left: "50%",
    transform: "translateX(-50%)",
    width: "min(680px, 95vw)",
    height: 460,
    background: "radial-gradient(closest-side, rgba(91,124,255,0.25), rgba(139,92,246,0.08) 55%, transparent 75%)",
    filter: "blur(20px)",
    pointerEvents: "none",
  };

  const cardStyle: CSSProperties = {
    position: "relative",
    width: "100%",
    maxWidth: 420,
    padding: 36,
    background: signal.card,
    border: `1px solid ${signal.border}`,
    borderRadius: 24,
  };

  const wordmarkStyle: CSSProperties = {
    display: "inline-flex",
    alignItems: "center",
    gap: 9,
    fontSize: 24,
    fontWeight: 700,
    color: signal.text,
    letterSpacing: "-0.01em",
    textDecoration: "none",
    marginBottom: 6,
  };

  const dotStyle: CSSProperties = {
    width: 9,
    height: 9,
    borderRadius: "50%",
    background: signal.glow,
    boxShadow: `0 0 12px ${signal.blue}`,
  };

  const subtitleStyle: CSSProperties = {
    fontFamily: signal.sans,
    fontSize: 15,
    color: signal.textDim,
    marginBottom: 32,
  };

  const labelStyle: CSSProperties = {
    fontFamily: signal.sans,
    fontSize: 14,
    fontWeight: 500,
    color: signal.textDim,
    marginBottom: 8,
    display: "block",
  };

  const inputStyle: CSSProperties = {
    width: "100%",
    padding: 14,
    borderRadius: 12,
    border: `1px solid ${signal.border}`,
    background: signal.cardRaised,
    color: signal.text,
    fontFamily: signal.sans,
    fontSize: 16,
    outline: "none",
    boxSizing: "border-box",
  };

  const buttonStyle: CSSProperties = {
    width: "100%",
    padding: 15,
    borderRadius: 12,
    border: "none",
    background: signal.glow,
    color: "#fff",
    fontFamily: signal.sans,
    fontSize: 16,
    fontWeight: 600,
    cursor: isPending ? "not-allowed" : "pointer",
    opacity: isPending ? 0.6 : 1,
    transition: "opacity 0.2s ease",
  };

  const errorStyle: CSSProperties = {
    fontFamily: signal.sans,
    fontSize: 14,
    color: "#FF6B6B",
    textAlign: "center",
    marginTop: 16,
  };

  const messageStyle: CSSProperties = {
    fontFamily: signal.sans,
    fontSize: 14,
    color: signal.textDim,
    textAlign: "center",
    marginTop: 16,
  };

  const helperStyle: CSSProperties = {
    fontFamily: signal.sans,
    fontSize: 14,
    color: signal.textDim,
    textAlign: "center",
    marginTop: 24,
  };

  const linkButtonStyle: CSSProperties = {
    background: "none",
    border: "none",
    color: signal.blue,
    cursor: "pointer",
    textDecoration: "underline",
    fontFamily: signal.sans,
    fontSize: 14,
    padding: 0,
  };

  return (
    <div style={containerStyle}>
      <div style={glow} aria-hidden />
      <div style={cardStyle}>
        <Link href="/" style={wordmarkStyle}>
          <span style={dotStyle} />
          Rinkler
        </Link>
        <div style={subtitleStyle}>Sign in to sync your Focus System. Same account as the app.</div>

        {!shouldEnterCode && (
          <>
            <div style={{ display: "flex", flexDirection: "column", gap: 10, marginBottom: 16 }}>
              <button
                type="button"
                onClick={() => signInWith("apple")}
                disabled={oauthBusy !== null}
                style={{
                  display: "flex", alignItems: "center", justifyContent: "center", gap: 10,
                  width: "100%", height: 48, borderRadius: 12, border: "none",
                  cursor: oauthBusy ? "default" : "pointer", background: "#fff", color: "#000",
                  fontFamily: signal.sans, fontSize: 15, fontWeight: 600, opacity: oauthBusy ? 0.7 : 1,
                }}
              >
                <AppleMark />
                {oauthBusy === "apple" ? "Connecting…" : "Continue with Apple"}
              </button>
              <button
                type="button"
                onClick={() => signInWith("google")}
                disabled={oauthBusy !== null}
                style={{
                  display: "flex", alignItems: "center", justifyContent: "center", gap: 10,
                  width: "100%", height: 48, borderRadius: 12, cursor: oauthBusy ? "default" : "pointer",
                  background: signal.cardRaised, color: signal.text, border: `1px solid ${signal.border}`,
                  fontFamily: signal.sans, fontSize: 15, fontWeight: 600, opacity: oauthBusy ? 0.7 : 1,
                }}
              >
                <GoogleMark />
                {oauthBusy === "google" ? "Connecting…" : "Continue with Google"}
              </button>
            </div>
            {oauthError && <p style={errorStyle}>{oauthError}</p>}
            <div style={{ display: "flex", alignItems: "center", gap: 12, margin: "4px 0 18px" }}>
              <span style={{ flex: 1, height: 1, background: signal.border }} />
              <span style={{ fontSize: 13, color: signal.textDim }}>or with email</span>
              <span style={{ flex: 1, height: 1, background: signal.border }} />
            </div>
          </>
        )}

        <form action={requestAction} style={{ display: shouldEnterCode ? "none" : "block" }}>
          <div style={{ marginBottom: 20 }}>
            <label style={labelStyle}>Email</label>
            <input
              name="email"
              type="email"
              placeholder="you@example.com"
              required
              autoCapitalize="none"
              defaultValue={email}
              style={inputStyle}
            />
          </div>
          <button type="submit" disabled={requestPending} style={buttonStyle}>
            {requestPending ? "Sending…" : "Send code"}
          </button>
        </form>

        {shouldEnterCode && (
          <form action={verifyAction}>
            <input type="hidden" name="email" value={email} />
            <div style={{ marginBottom: 20 }}>
              <label style={labelStyle}>Verification code</label>
              <input
                name="code"
                inputMode="numeric"
                pattern="[0-9]*"
                placeholder="000000"
                required
                maxLength={6}
                value={codeInput}
                onChange={(event) => {
                  setCodeInput(event.target.value.replace(/\D/g, "").slice(0, 6));
                }}
                style={{
                  ...inputStyle,
                  textAlign: "center",
                  letterSpacing: 8,
                  fontFamily: signal.mono,
                }}
              />
            </div>
            <button
              type="submit"
              disabled={verifyPending || codeInput.length !== 6}
              style={{
                ...buttonStyle,
                opacity: verifyPending || codeInput.length !== 6 ? 0.6 : 1,
              }}
            >
              {verifyPending ? "Verifying…" : "Verify"}
            </button>
          </form>
        )}

        {state?.error && <p style={errorStyle}>{state.error}</p>}
        {!state?.error && callbackError && (
          <p style={errorStyle}>That sign-in link could not be verified. Request a new code.</p>
        )}
        {statusMessage && <p style={messageStyle}>{statusMessage}</p>}

        {shouldEnterCode && (
          <form action={requestAction}>
            <input type="hidden" name="email" value={email} />
            <p style={helperStyle}>
              Wrong email?{" "}
              <button
                type="button"
                onClick={() => {
                  setCodeInput("");
                  window.location.href = "/login";
                }}
                style={linkButtonStyle}
              >
                Start over
              </button>
              {" "}or{" "}
              <button type="submit" disabled={requestPending} style={linkButtonStyle}>
                resend code
              </button>
            </p>
          </form>
        )}
      </div>
    </div>
  );
}

function AppleMark() {
  return (
    <svg width="16" height="16" viewBox="0 0 384 512" fill="currentColor" aria-hidden>
      <path d="M318.7 268.7c-.2-36.7 16.4-64.4 50-84.8-18.8-26.9-47.2-41.7-84.7-44.6-35.5-2.8-74.3 20.7-88.5 20.7-15 0-49.4-19.7-76.4-19.7C63.3 141.2 4 184.8 4 273.5q0 39.3 14.4 81.2c12.8 36.7 59 126.7 107.2 125.2 25.2-.6 43-17.9 75.8-17.9 31.8 0 48.3 17.9 76.4 17.9 48.6-.7 90.4-82.5 102.6-119.3-65.2-30.7-61.7-90-61.7-91.9zm-56.6-164.2c27.3-32.4 24.8-61.9 24-72.5-24.1 1.4-52 16.4-67.9 34.9-17.5 19.8-27.8 44.3-25.6 71.9 26.1 2 49.9-11.4 69.5-34.3z" />
    </svg>
  );
}

function GoogleMark() {
  return (
    <svg width="16" height="16" viewBox="0 0 48 48" aria-hidden>
      <path fill="#FFC107" d="M43.6 20.5H42V20H24v8h11.3C33.7 32.4 29.3 35 24 35c-6.6 0-12-5.4-12-12s5.4-12 12-12c3.1 0 5.9 1.2 8 3.1l5.7-5.7C34.6 5.1 29.6 3 24 3 12.4 3 3 12.4 3 24s9.4 21 21 21 21-9.4 21-21c0-1.3-.1-2.5-.4-3.5z" />
      <path fill="#FF3D00" d="M6.3 14.7l6.6 4.8C14.7 16 18.9 13 24 13c3.1 0 5.9 1.2 8 3.1l5.7-5.7C34.6 5.1 29.6 3 24 3 16 3 9.1 7.6 6.3 14.7z" />
      <path fill="#4CAF50" d="M24 45c5.2 0 9.9-2 13.4-5.2l-6.2-5.2C29.2 35.9 26.7 37 24 37c-5.3 0-9.7-2.6-11.3-7l-6.5 5C9.1 42.4 16 45 24 45z" />
      <path fill="#1976D2" d="M43.6 20.5H42V20H24v8h11.3c-.8 2.3-2.3 4.3-4.1 5.6l6.2 5.2C39.9 36.5 45 31 45 24c0-1.3-.1-2.5-.4-3.5z" />
    </svg>
  );
}
