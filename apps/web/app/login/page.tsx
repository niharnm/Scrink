"use client";

import { useActionState, useState, CSSProperties } from "react";
import { signIn, signUp } from "./actions";
import SkyBackground from "@/components/dashboard/SkyBackground";
import { theme } from "@/lib/theme";

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
    maxWidth: 420,
    padding: "44px 40px",
    background: theme.surface.card,
    border: `1px solid ${theme.surface.border}`,
    borderRadius: 28,
    backdropFilter: "blur(18px)",
    WebkitBackdropFilter: "blur(18px)",
    boxShadow: theme.surface.shadow,
  };

  const brandStyle: CSSProperties = {
    fontFamily: theme.fonts.display,
    fontSize: 52,
    color: theme.colors.white,
    textAlign: "center",
    letterSpacing: 0.5,
    lineHeight: 1.05,
  };

  const subtitleStyle: CSSProperties = {
    fontFamily: theme.fonts.body,
    fontSize: 17,
    color: theme.colors.white60,
    fontStyle: "italic",
    textAlign: "center",
    marginTop: 6,
    marginBottom: 40,
  };

  const labelStyle: CSSProperties = {
    fontFamily: theme.fonts.body,
    fontSize: 14,
    color: theme.colors.white60,
    marginBottom: 8,
    display: "block",
    letterSpacing: 0.3,
    textTransform: "uppercase",
  };

  const errorStyle: CSSProperties = {
    fontFamily: theme.fonts.body,
    fontSize: 14,
    color: theme.surface.danger,
    textAlign: "center",
    marginTop: 18,
  };

  const messageStyle: CSSProperties = {
    fontFamily: theme.fonts.body,
    fontSize: 14,
    color: theme.colors.white60,
    textAlign: "center",
    marginTop: 18,
  };

  const toggleStyle: CSSProperties = {
    fontFamily: theme.fonts.body,
    fontSize: 15,
    color: theme.colors.white60,
    textAlign: "center",
    marginTop: 28,
  };

  return (
    <SkyBackground animateClouds>
      <style>{`
        .rk-input {
          width: 100%;
          padding: 15px 18px;
          border-radius: 16px;
          border: 1px solid ${theme.surface.border};
          background: rgba(255,255,255,0.04);
          color: ${theme.colors.white};
          font-family: ${theme.fonts.body};
          font-size: 17px;
          outline: none;
          box-sizing: border-box;
          transition: border-color .18s ease, background .18s ease, box-shadow .18s ease;
        }
        .rk-input::placeholder { color: rgba(255,255,255,0.32); }
        .rk-input:focus {
          border-color: ${theme.surface.accent};
          background: rgba(255,255,255,0.07);
          box-shadow: 0 0 0 4px ${theme.surface.accentSoft};
        }
        .rk-submit {
          width: 100%;
          padding: 16px;
          border-radius: 16px;
          border: none;
          background: ${theme.surface.accent};
          color: ${theme.colors.white};
          font-family: ${theme.fonts.display};
          font-size: 21px;
          letter-spacing: 0.3px;
          cursor: pointer;
          transition: filter .18s ease, transform .06s ease, opacity .18s ease;
        }
        .rk-submit:hover:not(:disabled) { filter: brightness(1.08); }
        .rk-submit:active:not(:disabled) { transform: translateY(1px); }
        .rk-submit:disabled { opacity: 0.55; cursor: not-allowed; }
        .rk-link {
          background: none; border: none; color: ${theme.colors.white};
          cursor: pointer; font-family: ${theme.fonts.body}; font-size: 15px;
          padding: 0; text-decoration: underline; text-underline-offset: 3px;
        }
        .rk-link:hover { color: ${theme.surface.accent}; }
      `}</style>

      <div style={containerStyle}>
        <div style={cardStyle}>
          <div style={brandStyle}>Rinkler</div>
          <div style={subtitleStyle}>keep the useful parts.</div>

          <form action={action}>
            <div style={{ marginBottom: 20 }}>
              <label style={labelStyle}>Email</label>
              <input
                className="rk-input"
                name="email"
                type="email"
                placeholder="you@example.com"
                required
                autoCapitalize="none"
              />
            </div>
            <div style={{ marginBottom: 32 }}>
              <label style={labelStyle}>Password</label>
              <input
                className="rk-input"
                name="password"
                type="password"
                placeholder="••••••"
                required
                minLength={6}
              />
            </div>
            <button type="submit" disabled={pending} className="rk-submit">
              {pending ? "..." : isSignUp ? "Sign Up" : "Sign In"}
            </button>
          </form>

          {state?.error && <p style={errorStyle}>{state.error}</p>}
          {state && "message" in state && state.message && (
            <p style={messageStyle}>{state.message}</p>
          )}

          <p style={toggleStyle}>
            {isSignUp ? "Already have an account?" : "Need an account?"}{" "}
            <button onClick={() => setIsSignUp(!isSignUp)} className="rk-link">
              {isSignUp ? "Sign In" : "Sign Up"}
            </button>
          </p>
        </div>
      </div>
    </SkyBackground>
  );
}
