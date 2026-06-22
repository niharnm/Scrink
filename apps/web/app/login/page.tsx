"use client";

import { useActionState, useEffect, useState, CSSProperties } from "react";
import Link from "next/link";
import { requestEmailCode, verifyEmailCode } from "./actions";
import { signal } from "@/lib/signal";

export default function LoginPage() {
  const [requestState, requestAction, requestPending] = useActionState(requestEmailCode, null);
  const [verifyState, verifyAction, verifyPending] = useActionState(verifyEmailCode, null);
  const [codeInput, setCodeInput] = useState("");
  const [callbackError, setCallbackError] = useState(false);

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
        <div style={subtitleStyle}>Sign in to sync your Focus System.</div>

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
