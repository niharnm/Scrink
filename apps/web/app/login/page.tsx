"use client";

import { useActionState, useEffect, useRef, useState, CSSProperties } from "react";
import Link from "next/link";
import Script from "next/script";
import { requestEmailCode, verifyEmailCode } from "./actions";
import { createClient } from "@/lib/supabase/client";
import { signal } from "@/lib/signal";

type TurnstileApi = {
  render: (el: HTMLElement, opts: Record<string, unknown>) => string;
  reset: (id: string) => void;
};
const getTurnstile = () => (window as unknown as { turnstile?: TurnstileApi }).turnstile;

// Two swordsmen ambush the captcha the moment it clears, chase it off-screen, then
// shove the header back into place. Pure CSS choreography, ~2.2s, reduced-motion safe.
const CAPTCHA_CSS = `
@keyframes rinkPulse{0%,100%{opacity:1}50%{opacity:.3}}
.cap-wrap{overflow:hidden}
.cap-wrap.dying{animation:capCollapse 2.2s ease forwards}
@keyframes capCollapse{0%,72%{max-height:60px;opacity:1;margin-bottom:14px}100%{max-height:0;opacity:0;margin-bottom:0}}
.cap-chip{display:flex;align-items:center;gap:10px;padding:11px 14px;border-radius:10px;border:1px solid ${signal.border};background:${signal.card};margin-bottom:14px}
.cap-chip.ok{border-color:rgba(91,209,122,.35)}
.cap-chip.dying{animation:capDie 2.2s ease-in forwards}
@keyframes capDie{0%,34%{transform:none;opacity:1}40%{transform:translateX(-7px) rotate(-4deg)}47%{transform:translateX(9px) rotate(4deg)}54%{transform:translateX(-5px) rotate(-3deg)}60%{transform:translateX(3px) rotate(2deg)}70%{transform:translate(150%,-12%) rotate(40deg);opacity:.85}100%{transform:translate(195%,28%) rotate(72deg);opacity:0}}
.cap-dot{width:8px;height:8px;border-radius:50%;background:${signal.textDim};flex-shrink:0;animation:rinkPulse 1.4s ease-in-out infinite}
.cap-check{color:#5BD17A;font-size:14px;font-weight:700;flex-shrink:0}
.cap-text{font-size:13.5px;color:${signal.textDim};flex:1}
.cap-text.ok{color:${signal.text}}
.cap-brand{font-size:10px;letter-spacing:.08em;text-transform:uppercase;color:rgba(255,255,255,.32)}
.rink-hdr.shoved{animation:hdrShove 2.2s ease forwards}
@keyframes hdrShove{0%,80%{transform:translateY(0)}87%{transform:translateY(11px)}94%{transform:translateY(-3px)}100%{transform:translateY(0)}}
.slay-overlay{position:absolute;left:0;right:0;top:92px;height:50px;pointer-events:none;z-index:5}
.runner{position:absolute;top:0;left:50%}
.runner.l{animation:slayL 2.2s cubic-bezier(.4,0,.45,1) forwards}
.runner.r{animation:slayR 2.2s cubic-bezier(.4,0,.45,1) forwards}
@keyframes slayL{0%{transform:translate(-210px,0);opacity:0}10%{opacity:1}30%{transform:translate(-62px,0)}40%{transform:translate(-54px,-3px)}52%{transform:translate(-62px,0)}72%{transform:translate(-62px,0);opacity:1}87%{transform:translate(-36px,-150px);opacity:1}100%{transform:translate(-28px,-250px);opacity:0}}
@keyframes slayR{0%{transform:translate(210px,0) scaleX(-1);opacity:0}10%{opacity:1}30%{transform:translate(30px,0) scaleX(-1)}40%{transform:translate(22px,-3px) scaleX(-1)}52%{transform:translate(30px,0) scaleX(-1)}72%{transform:translate(30px,0) scaleX(-1);opacity:1}87%{transform:translate(6px,-150px) scaleX(-1);opacity:1}100%{transform:translate(-2px,-250px) scaleX(-1);opacity:0}}
.legA{transform-origin:17px 30px;animation:legSwA .26s linear infinite}
.legB{transform-origin:17px 30px;animation:legSwB .26s linear infinite}
@keyframes legSwA{0%,100%{transform:rotate(18deg)}50%{transform:rotate(-18deg)}}
@keyframes legSwB{0%,100%{transform:rotate(-18deg)}50%{transform:rotate(18deg)}}
.sword-arm{transform-origin:17px 19px;animation:slash 2.2s ease forwards}
@keyframes slash{0%,32%{transform:rotate(0)}37%{transform:rotate(-70deg)}44%{transform:rotate(55deg)}52%{transform:rotate(0)}100%{transform:rotate(0)}}
@media (prefers-reduced-motion:reduce){.cap-wrap.dying,.cap-chip.dying,.rink-hdr.shoved,.runner.l,.runner.r,.sword-arm,.legA,.legB,.cap-dot{animation:none}}
`;

function Stickman() {
  return (
    <svg width="32" height="42" viewBox="0 0 40 48" fill="none" stroke="#ECECEE" strokeWidth="2.3" strokeLinecap="round" aria-hidden>
      <circle cx="17" cy="9" r="5.5" fill="#ECECEE" stroke="none" />
      <line x1="17" y1="14.5" x2="17" y2="30" />
      <line className="legA" x1="17" y1="30" x2="10" y2="45" />
      <line className="legB" x1="17" y1="30" x2="24" y2="45" />
      <line x1="17" y1="20" x2="8" y2="26" />
      <g className="sword-arm">
        <line x1="17" y1="19" x2="29" y2="14" />
        <line x1="29" y1="14" x2="38" y2="5" strokeWidth="2.7" />
        <line x1="27" y1="16.5" x2="31" y2="12.5" />
      </g>
    </svg>
  );
}

export default function LoginPage() {
  const [requestState, requestAction, requestPending] = useActionState(requestEmailCode, null);
  const [verifyState, verifyAction, verifyPending] = useActionState(verifyEmailCode, null);
  const [codeInput, setCodeInput] = useState("");
  const [callbackError, setCallbackError] = useState(false);
  const [oauthBusy, setOauthBusy] = useState<"google" | "apple" | null>(null);
  const [oauthError, setOauthError] = useState<string | null>(null);
  const [captchaToken, setCaptchaToken] = useState("");
  const siteKey = process.env.NEXT_PUBLIC_TURNSTILE_SITE_KEY;
  const widgetRef = useRef<HTMLDivElement>(null);
  const widgetId = useRef<string | null>(null);
  // When a captcha is configured, hold actions until we have a token.
  const captchaReady = !siteKey || captchaToken.length > 0;
  const [slay, setSlay] = useState<"idle" | "run" | "done">("idle");

  // Render the Turnstile widget once its script loads (explicit mode).
  const renderTurnstile = () => {
    const t = getTurnstile();
    if (!siteKey || !widgetRef.current || !t || widgetId.current) return;
    widgetId.current = t.render(widgetRef.current, {
      sitekey: siteKey,
      callback: (token: string) => setCaptchaToken(token),
      "expired-callback": () => setCaptchaToken(""),
      "error-callback": () => setCaptchaToken(""),
      theme: "dark",
      size: "flexible",
      // Invisible for normal visitors — only suspicious traffic ever sees a box.
      // We surface our own status chip instead of the default Cloudflare widget.
      appearance: "interaction-only",
    });
  };

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
  // A Turnstile token is single-use; after each email-send attempt, get a fresh one.
  useEffect(() => {
    const t = getTurnstile();
    if (widgetId.current && t) {
      t.reset(widgetId.current);
      setCaptchaToken("");
    }
  }, [requestState]);
  // The little ambush: the first time the captcha clears, send in the swordsmen.
  useEffect(() => {
    if (!captchaToken || slay !== "idle") return;
    const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    if (reduce) {
      setSlay("done");
      return;
    }
    setSlay("run");
    const id = setTimeout(() => setSlay("done"), 2400);
    return () => clearTimeout(id);
  }, [captchaToken, slay]);

  const containerStyle: CSSProperties = {
    display: "flex",
    flexDirection: "column",
    alignItems: "center",
    justifyContent: "center",
    minHeight: "100vh",
    padding: 24,
    background: signal.bg,
    fontFamily: signal.sans,
  };

  const cardStyle: CSSProperties = {
    width: "100%",
    maxWidth: 380,
    padding: 4,
    position: "relative",
  };

  const wordmarkStyle: CSSProperties = {
    display: "inline-block",
    fontSize: 22,
    fontWeight: 600,
    color: signal.text,
    letterSpacing: "-0.01em",
    textDecoration: "none",
    marginBottom: 8,
  };

  const subtitleStyle: CSSProperties = {
    fontFamily: signal.sans,
    fontSize: 14.5,
    color: signal.textDim,
    marginBottom: 30,
    lineHeight: 1.5,
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
    padding: 13,
    borderRadius: 10,
    border: `1px solid ${signal.border}`,
    background: signal.card,
    color: signal.text,
    fontFamily: signal.sans,
    fontSize: 15,
    outline: "none",
    boxSizing: "border-box",
  };

  const buttonStyle: CSSProperties = {
    width: "100%",
    padding: 14,
    borderRadius: 10,
    border: "none",
    background: signal.text,
    color: "#08080A",
    fontFamily: signal.sans,
    fontSize: 15,
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
      <div style={cardStyle}>
        <div className={slay === "run" ? "rink-hdr shoved" : "rink-hdr"}>
          <Link href="/" style={wordmarkStyle}>
            Rinkler
          </Link>
          <div style={subtitleStyle}>
            hop on the waitlist. Rinkler drops July 10, and youll be first to know the second its ready.
          </div>
        </div>

        {!shouldEnterCode && (
          <>
            {siteKey && (
              <>
                <style>{CAPTCHA_CSS}</style>
                <Script
                  src="https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit"
                  strategy="afterInteractive"
                  onLoad={renderTurnstile}
                />
                {slay !== "done" && (
                  <div className={slay === "run" ? "cap-wrap dying" : "cap-wrap"}>
                    <div className={`cap-chip${captchaToken ? " ok" : ""}${slay === "run" ? " dying" : ""}`}>
                      {captchaToken ? <span className="cap-check">✓</span> : <span className="cap-dot" />}
                      <span className={`cap-text${captchaToken ? " ok" : ""}`}>
                        {captchaToken ? "youre human, nice" : "making sure youre human…"}
                      </span>
                      <span className="cap-brand">Cloudflare</span>
                    </div>
                  </div>
                )}
                {/* Turnstile renders here — kept mounted so tokens keep refreshing.
                    Invisible for normal visitors (interaction-only); a real challenge,
                    if ever needed, shows up here dark + full-width. */}
                <div ref={widgetRef} />
                {slay === "run" && (
                  <div className="slay-overlay" aria-hidden>
                    <div className="runner l"><Stickman /></div>
                    <div className="runner r"><Stickman /></div>
                  </div>
                )}
              </>
            )}
            <div style={{ display: "flex", flexDirection: "column", gap: 10, marginBottom: 16 }}>
              <button
                type="button"
                onClick={() => signInWith("apple")}
                disabled={oauthBusy !== null}
                style={{
                  display: "flex", alignItems: "center", justifyContent: "center", gap: 10,
                  width: "100%", height: 46, borderRadius: 10, border: "none",
                  cursor: oauthBusy ? "default" : "pointer", background: signal.text, color: "#08080A",
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
                  width: "100%", height: 46, borderRadius: 10, cursor: oauthBusy ? "default" : "pointer",
                  background: "transparent", color: signal.text, border: `1px solid ${signal.borderStrong}`,
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
          <input type="hidden" name="captchaToken" value={captchaToken} />
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
          <button type="submit" disabled={requestPending || !captchaReady} style={buttonStyle}>
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
