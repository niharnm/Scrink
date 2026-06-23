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

// Easter egg: when the captcha clears, two swordsmen charge in, chase it off-screen,
// then run up and around to shove the header back into place. If it gets rejected,
// a lone swordsman whiffs, the captcha dodges, and you try again. Pure CSS,
// reduced-motion safe. Kill ~3.4s, reject ~1.9s.
const CAPTCHA_CSS = `
@keyframes rinkPulse{0%,100%{opacity:1}50%{opacity:.3}}
.cap-wrap{overflow:hidden}
.cap-wrap.dying{animation:capCollapse 3.4s ease forwards}
@keyframes capCollapse{0%,52%{max-height:60px;opacity:1;margin-bottom:14px}60%,100%{max-height:0;opacity:0;margin-bottom:0}}
.cap-chip{display:flex;align-items:center;gap:10px;padding:11px 14px;border-radius:10px;border:1px solid ${signal.border};background:${signal.card};margin-bottom:14px}
.cap-chip.ok{border-color:rgba(91,209,122,.35)}
.cap-chip.bad{border-color:rgba(255,107,107,.5)}
.cap-chip.dying{animation:capDie 3.4s ease-in forwards}
@keyframes capDie{0%,20%{transform:none;opacity:1}26%{transform:translateX(-7px) rotate(-4deg)}31%{transform:translateX(9px) rotate(4deg)}37%{transform:translateX(-6px) rotate(-3deg)}43%{transform:translateX(4px) rotate(2deg)}52%{transform:translate(150%,-12%) rotate(40deg);opacity:.85}60%,100%{transform:translate(210%,30%) rotate(80deg);opacity:0}}
.cap-chip.dodging{animation:capDodge 1.9s ease}
@keyframes capDodge{0%,24%{transform:none}30%{transform:translate(13px,-5px) rotate(2deg)}38%{transform:translateX(-4px)}46%{transform:translateX(4px)}54%{transform:translateX(-6px)}62%{transform:translateX(5px)}70%{transform:translateX(-3px)}100%{transform:none}}
.cap-dot{width:8px;height:8px;border-radius:50%;background:${signal.textDim};flex-shrink:0;animation:rinkPulse 1.4s ease-in-out infinite}
.cap-check{color:#5BD17A;font-size:14px;font-weight:700;flex-shrink:0}
.cap-x{color:#FF6B6B;font-size:14px;font-weight:700;flex-shrink:0}
.cap-text{font-size:13.5px;color:${signal.textDim};flex:1}
.cap-text.ok{color:${signal.text}}
.cap-text.bad{color:#FF8C8C}
.cap-brand{font-size:10px;letter-spacing:.08em;text-transform:uppercase;color:rgba(255,255,255,.32)}
.rink-hdr.shoved{animation:hdrShove 3.4s ease forwards}
@keyframes hdrShove{0%,78%{transform:translateY(0)}85%{transform:translateY(16px)}92%{transform:translateY(-4px)}100%{transform:translateY(0)}}
.slay-overlay{position:absolute;left:0;right:0;top:92px;height:50px;pointer-events:none;z-index:5}
.runner{position:absolute;top:0;left:50%}
.bob{display:inline-block;animation:bob .24s ease-in-out infinite}
@keyframes bob{0%,100%{transform:translateY(0)}50%{transform:translateY(-3px)}}
.runner.l{animation:slayL 3.4s linear forwards}
.runner.r{animation:slayR 3.4s linear forwards}
.runner.whiff{animation:whiff 1.9s ease-in forwards}
@keyframes slayL{0%{transform:translate(-210px,0);opacity:0}8%{opacity:1}22%{transform:translate(-62px,0)}28%{transform:translate(-52px,-3px)}34%{transform:translate(-62px,0)}48%{transform:translate(-142px,6px)}60%{transform:translate(-150px,-72px)}70%{transform:translate(-118px,-132px)}80%{transform:translate(-72px,-150px)}86%{transform:translate(-64px,-134px)}92%{transform:translate(-92px,-148px)}100%{transform:translate(-205px,-160px);opacity:0}}
@keyframes slayR{0%{transform:translate(210px,0) scaleX(-1);opacity:0}8%{opacity:1}22%{transform:translate(30px,0) scaleX(-1)}28%{transform:translate(20px,-3px) scaleX(-1)}34%{transform:translate(30px,0) scaleX(-1)}48%{transform:translate(110px,6px) scaleX(-1)}60%{transform:translate(118px,-72px) scaleX(-1)}70%{transform:translate(86px,-132px) scaleX(-1)}80%{transform:translate(40px,-150px) scaleX(-1)}86%{transform:translate(32px,-134px) scaleX(-1)}92%{transform:translate(60px,-148px) scaleX(-1)}100%{transform:translate(173px,-160px) scaleX(-1);opacity:0}}
@keyframes whiff{0%{transform:translate(-200px,0) rotate(0);opacity:0}12%{opacity:1}30%{transform:translate(-34px,0) rotate(0)}40%{transform:translate(-20px,-4px) rotate(0)}52%{transform:translate(46px,-6px) rotate(18deg)}66%{transform:translate(120px,16px) rotate(150deg)}100%{transform:translate(245px,52px) rotate(350deg);opacity:0}}
.legA{transform-origin:17px 30px;animation:legSwA .24s linear infinite}
.legB{transform-origin:17px 30px;animation:legSwB .24s linear infinite}
@keyframes legSwA{0%,100%{transform:rotate(20deg)}50%{transform:rotate(-20deg)}}
@keyframes legSwB{0%,100%{transform:rotate(-20deg)}50%{transform:rotate(20deg)}}
.sword-arm{transform-origin:17px 19px}
.runner.l .sword-arm,.runner.r .sword-arm{animation:slash 3.4s ease forwards}
.runner.whiff .sword-arm{animation:slashW 1.9s ease forwards}
@keyframes slash{0%,22%{transform:rotate(0)}26%{transform:rotate(-70deg)}32%{transform:rotate(55deg)}40%{transform:rotate(0)}100%{transform:rotate(0)}}
@keyframes slashW{0%,30%{transform:rotate(0)}38%{transform:rotate(-78deg)}46%{transform:rotate(62deg)}56%{transform:rotate(0)}100%{transform:rotate(0)}}
@media (prefers-reduced-motion:reduce){.cap-wrap.dying,.cap-chip.dying,.cap-chip.dodging,.rink-hdr.shoved,.runner,.bob,.sword-arm,.legA,.legB,.cap-dot{animation:none}}
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
  const [phase, setPhase] = useState<"pending" | "slaying" | "won" | "rejected">("pending");
  const [rejectSignal, setRejectSignal] = useState(0);
  const phaseRef = useRef(phase);
  phaseRef.current = phase;

  // Render the Turnstile widget once its script loads (explicit mode).
  const renderTurnstile = () => {
    const t = getTurnstile();
    if (!siteKey || !widgetRef.current || !t || widgetId.current) return;
    widgetId.current = t.render(widgetRef.current, {
      sitekey: siteKey,
      callback: (token: string) => setCaptchaToken(token),
      "expired-callback": () => { setCaptchaToken(""); setRejectSignal((n) => n + 1); },
      "error-callback": () => { setCaptchaToken(""); setRejectSignal((n) => n + 1); },
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
  // The ambush: the first time the captcha clears, send in the swordsmen.
  useEffect(() => {
    if (!captchaToken || phase !== "pending") return;
    const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    if (reduce) {
      setPhase("won");
      return;
    }
    setPhase("slaying");
    const id = setTimeout(() => setPhase("won"), 3500);
    return () => clearTimeout(id);
  }, [captchaToken, phase]);
  // Rejected/expired: a lone swordsman whiffs, the captcha dodges, you go again.
  useEffect(() => {
    if (rejectSignal === 0) return;
    const t = getTurnstile();
    // If it expires after a win, just silently re-arm the invisible widget.
    if (phaseRef.current === "won") {
      if (widgetId.current && t) t.reset(widgetId.current);
      return;
    }
    const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    setPhase("rejected");
    const id = setTimeout(() => {
      const tt = getTurnstile();
      if (widgetId.current && tt) tt.reset(widgetId.current);
      setCaptchaToken("");
      setPhase("pending");
    }, reduce ? 800 : 2000);
    return () => clearTimeout(id);
  }, [rejectSignal]);

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
        <div className={phase === "slaying" ? "rink-hdr shoved" : "rink-hdr"}>
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
                {phase !== "won" && (
                  <div className={`cap-wrap${phase === "slaying" ? " dying" : ""}`}>
                    <div
                      className={
                        "cap-chip" +
                        (phase === "slaying" ? " ok dying" : "") +
                        (phase === "rejected" ? " bad dodging" : "")
                      }
                    >
                      {phase === "slaying" ? (
                        <span className="cap-check">✓</span>
                      ) : phase === "rejected" ? (
                        <span className="cap-x">✗</span>
                      ) : (
                        <span className="cap-dot" />
                      )}
                      <span
                        className={
                          "cap-text" +
                          (phase === "slaying" ? " ok" : "") +
                          (phase === "rejected" ? " bad" : "")
                        }
                      >
                        {phase === "slaying"
                          ? "youre human, nice"
                          : phase === "rejected"
                            ? "that one didnt count, hang on…"
                            : "making sure youre human…"}
                      </span>
                      <span className="cap-brand">Cloudflare</span>
                    </div>
                  </div>
                )}
                {/* Turnstile renders here — kept mounted so tokens keep refreshing.
                    Invisible for normal visitors (interaction-only); a real challenge,
                    if ever needed, shows up here dark + full-width. */}
                <div ref={widgetRef} />
                {phase === "slaying" && (
                  <div className="slay-overlay" aria-hidden>
                    <div className="runner l"><span className="bob"><Stickman /></span></div>
                    <div className="runner r"><span className="bob"><Stickman /></span></div>
                  </div>
                )}
                {phase === "rejected" && (
                  <div className="slay-overlay" aria-hidden>
                    <div className="runner whiff"><span className="bob"><Stickman /></span></div>
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
