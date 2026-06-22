"use client";

import { useActionState, useEffect, useState, CSSProperties } from "react";
import { requestEmailCode, verifyEmailCode } from "./actions";
import SkyBackground from "@/components/dashboard/SkyBackground";

const theme = {
  skyBlue: "#7F85FF",
  aurora: "linear-gradient(120deg, #5BE1C6, #8A7CFF)",
  white: "#FFFFFF",
  white10: "rgba(255,255,255,0.06)",
  white30: "rgba(255,255,255,0.14)",
  white60: "rgba(255,255,255,0.62)",
  display: "'Geist', system-ui, sans-serif",
  body: "'Geist', system-ui, sans-serif",
};

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
  };

  const cardStyle: CSSProperties = {
    width: "100%",
    maxWidth: 400,
    padding: 40,
    background: "rgba(255,255,255,0.05)",
    border: "1px solid rgba(255,255,255,0.12)",
    borderRadius: 28,
    backdropFilter: "blur(14px)",
  };

  const titleStyle: CSSProperties = {
    fontFamily: theme.display,
    fontSize: 44,
    fontWeight: 700,
    letterSpacing: "-0.5px",
    color: theme.white,
    textAlign: "center",
    marginBottom: 8,
  };

  const subtitleStyle: CSSProperties = {
    fontFamily: theme.body,
    fontSize: 17,
    color: theme.white60,
    textAlign: "center",
    marginBottom: 40,
  };

  const labelStyle: CSSProperties = {
    fontFamily: theme.body,
    fontSize: 16,
    color: theme.white,
    marginBottom: 8,
    display: "block",
  };

  const inputStyle: CSSProperties = {
    width: "100%",
    padding: 16,
    borderRadius: 16,
    border: `1px solid ${theme.white30}`,
    background: theme.white10,
    color: theme.white,
    fontFamily: theme.body,
    fontSize: 18,
    outline: "none",
    boxSizing: "border-box",
  };

  const buttonStyle: CSSProperties = {
    width: "100%",
    padding: 16,
    borderRadius: 16,
    border: "none",
    background: theme.aurora,
    color: "rgba(0,0,0,0.85)",
    fontFamily: theme.display,
    fontWeight: 600,
    fontSize: 18,
    cursor: isPending ? "not-allowed" : "pointer",
    opacity: isPending ? 0.6 : 1,
    transition: "opacity 0.2s ease",
  };

  const errorStyle: CSSProperties = {
    fontFamily: theme.body,
    fontSize: 14,
    color: "#FF6B6B",
    textAlign: "center",
    marginTop: 16,
  };

  const messageStyle: CSSProperties = {
    fontFamily: theme.body,
    fontSize: 14,
    color: theme.white60,
    textAlign: "center",
    marginTop: 16,
  };

  const helperStyle: CSSProperties = {
    fontFamily: theme.body,
    fontSize: 15,
    color: theme.white60,
    textAlign: "center",
    marginTop: 24,
  };

  const linkButtonStyle: CSSProperties = {
    background: "none",
    border: "none",
    color: theme.white,
    cursor: "pointer",
    textDecoration: "underline",
    fontFamily: theme.body,
    fontSize: 15,
    padding: 0,
  };

  return (
    <SkyBackground animateClouds>
      <div style={containerStyle}>
        <div style={cardStyle}>
          <div style={titleStyle}>Rinkler</div>
          <div style={subtitleStyle}>keep the useful parts.</div>

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
              {requestPending ? "..." : "Send Code"}
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
                    letterSpacing: 6,
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
                {verifyPending ? "..." : "Verify"}
              </button>
            </form>
          )}

          {state?.error && <p style={errorStyle}>{state.error}</p>}
          {!state?.error && callbackError && (
            <p style={errorStyle}>That sign-in link could not be verified. Request a new code.</p>
          )}
          {statusMessage && (
            <p style={messageStyle}>{statusMessage}</p>
          )}

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
    </SkyBackground>
  );
}
