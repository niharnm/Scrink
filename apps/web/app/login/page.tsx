"use client";

import { useActionState, useState, CSSProperties } from "react";
import { signIn, signUp } from "./actions";
import SkyBackground from "@/components/dashboard/SkyBackground";

const theme = {
  skyBlue: "#3A8DDE",
  white: "#FFFFFF",
  white10: "rgba(255,255,255,0.1)",
  white30: "rgba(255,255,255,0.3)",
  white60: "rgba(255,255,255,0.6)",
  display: "'Coolvetica', system-ui, sans-serif",
  body: "'Coolvetica', system-ui, sans-serif",
};

export default function LoginPage() {
  const [isSignUp, setIsSignUp] = useState(false);
  const [signInState, signInAction, signInPending] = useActionState(signIn, null);
  const [signUpState, signUpAction, signUpPending] = useActionState(signUp, null);

  const action = isSignUp ? signUpAction : signInAction;
  const pending = isSignUp ? signUpPending : signInPending;
  const state = isSignUp ? signUpState : signInState;

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
  };

  const titleStyle: CSSProperties = {
    fontFamily: theme.display,
    fontSize: 48,
    color: theme.white,
    textAlign: "center",
    marginBottom: 8,
  };

  const subtitleStyle: CSSProperties = {
    fontFamily: theme.body,
    fontSize: 18,
    color: theme.white60,
    fontStyle: "italic",
    textAlign: "center",
    marginBottom: 48,
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
    borderRadius: 28,
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
    borderRadius: 28,
    border: `2px solid ${theme.white}`,
    background: theme.skyBlue,
    color: theme.white,
    fontFamily: theme.display,
    fontSize: 22,
    cursor: pending ? "not-allowed" : "pointer",
    opacity: pending ? 0.6 : 1,
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

  const toggleStyle: CSSProperties = {
    fontFamily: theme.body,
    fontSize: 15,
    color: theme.white60,
    textAlign: "center",
    marginTop: 24,
  };

  const toggleBtnStyle: CSSProperties = {
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
          <div style={titleStyle}>BUBBLE</div>
          <div style={subtitleStyle}>into the clouds.</div>

          <form action={action}>
            <div style={{ marginBottom: 20 }}>
              <label style={labelStyle}>Email</label>
              <input
                name="email"
                type="email"
                placeholder="you@example.com"
                required
                autoCapitalize="none"
                style={inputStyle}
              />
            </div>
            <div style={{ marginBottom: 32 }}>
              <label style={labelStyle}>Password</label>
              <input
                name="password"
                type="password"
                placeholder="••••••"
                required
                minLength={6}
                style={inputStyle}
              />
            </div>
            <button type="submit" disabled={pending} style={buttonStyle}>
              {pending ? "..." : isSignUp ? "Sign Up" : "Sign In"}
            </button>
          </form>

          {state?.error && <p style={errorStyle}>{state.error}</p>}
          {state && "message" in state && state.message && (
            <p style={messageStyle}>{state.message}</p>
          )}

          <p style={toggleStyle}>
            {isSignUp ? "Already have an account?" : "Need an account?"}{" "}
            <button onClick={() => setIsSignUp(!isSignUp)} style={toggleBtnStyle}>
              {isSignUp ? "Sign In" : "Sign Up"}
            </button>
          </p>
        </div>
      </div>
    </SkyBackground>
  );
}
