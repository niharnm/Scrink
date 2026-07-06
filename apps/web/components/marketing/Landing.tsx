"use client";

import Link from "next/link";
import { useState, type CSSProperties } from "react";
import { signal } from "@/lib/signal";
import AppShowcase from "./AppShowcase";
import Reveal from "./Reveal";
import Countdown from "./Countdown";
import Marquee from "./Marquee";

/**
 * Rinkler marketing landing — stark, true black, casual real voice (lowercase,
 * no em dashes). Opens on JUST the countdown splash; "what is this" reveals the
 * rest of the page. Scroll-reveals on each section.
 */
export default function Landing({ loggedIn }: { loggedIn: boolean }) {
  const ctaHref = loggedIn ? "/dashboard" : "/login";
  const ctaLabel = loggedIn ? "open dashboard" : "get early access";

  const [open, setOpen] = useState(false);
  const reveal = () => {
    setOpen(true);
    const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    // The page is already there below the splash; we just glide down to it so it
    // feels like one calm scroll, not the whole thing popping in then jumping.
    requestAnimationFrame(() => {
      const el = document.getElementById("more");
      if (!el) return;
      if (reduce) {
        el.scrollIntoView();
        return;
      }
      slowScrollTo(el.getBoundingClientRect().top + window.scrollY, 1400);
    });
  };

  return (
    <div style={page}>
      <style dangerouslySetInnerHTML={{ __html: css }} />

      {/* Nav (slides down when the page is revealed) */}
      {open && (
        <header style={navBar} className="nav-in">
          <div style={navInner}>
            <Link href="/" style={wordmark}>
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img src="/rinkler-mark.png" alt="" width={22} height={22} style={{ display: "block" }} />
              Rinkler
            </Link>
            <nav style={navRight} className="nav-links">
              <a href="#how" style={navLink}>how</a>
              <Link href="/privacy" style={navLink}>privacy</Link>
              <Link href="/login" style={navLink}>log in</Link>
              <Link href={ctaHref} style={lightBtn} className="light-btn">{ctaLabel}</Link>
            </nav>
          </div>
        </header>
      )}

      <main style={main}>
        {/* Splash — countdown */}
        <section style={splash}>
          <Reveal y={14}>
            <div style={splashLogo}>
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img src="/rinkler-mark.png" alt="" width={40} height={40} style={{ display: "block" }} />
              <span style={splashWord}>Rinkler</span>
            </div>
            <p style={splashTag}>the app that kills the <EndlessScroll />, not your whole phone</p>

            <div style={{ marginTop: "clamp(28px, 5vh, 52px)" }}>
              <div style={countLabel}>launching in</div>
              <Countdown />
            </div>

            <div style={{ display: "flex", justifyContent: "center", marginTop: "clamp(32px, 5vh, 48px)" }}>
              <Link href={ctaHref} style={lightBtnLg} className="light-btn">{ctaLabel}</Link>
            </div>

            <button onClick={reveal} style={learnMore} className="text-btn">what is this ↓</button>
          </Reveal>
        </section>

        {open && (
          <div className="reveal-content">
        {/* Hero */}
        <Reveal y={18}>
          <section id="more" style={{ ...section, paddingTop: "clamp(92px, 12vh, 124px)", paddingBottom: "clamp(72px, 12vh, 150px)" }}>
            <h1 style={h1}>
              your phone isnt<br className="br-hide" /> the problem.
              <br />
              <span style={{ color: signal.textFaint }}>the feed is.</span>
            </h1>
            <p style={{ ...lede, marginTop: 28 }}>
              you sit down for a sec and somehow its 1am. Rinkler takes the Reels
              and TikToks doing that to you, and leaves your DMs, search and
              people alone.
            </p>
            <div style={ctaRow}>
              <Link href={ctaHref} style={lightBtn} className="light-btn">{ctaLabel}</Link>
              <a href="#difference" style={textBtn} className="text-btn">see why its different →</a>
            </div>
          </section>
        </Reveal>

        {/* Endless scroll marquee */}
        <Marquee />

        {/* App showcase */}
        <Reveal><AppShowcase /></Reveal>

        <Rule />

        {/* Scalpel */}
        <Reveal>
          <section id="difference" style={section}>
            <h2 style={h2}>it cuts the feed, not the whole app.</h2>
            <div style={{ ...compareGrid, marginTop: 36 }} className="compare">
              <div style={{ paddingRight: 32 }}>
                <div style={colLabel}>blanket blockers</div>
                {compareBad.map((t) => <CompareRow key={t} text={t} good={false} />)}
              </div>
              <div style={{ paddingLeft: 32, borderLeft: `1px solid ${signal.border}` }} className="compare-right">
                <div style={{ ...colLabel, color: signal.text }}>rinkler</div>
                {compareGood.map((t) => <CompareRow key={t} text={t} good />)}
              </div>
            </div>
            <p style={{ ...statement, color: signal.text, marginTop: 30 }}>
              block whole apps, or just the feeds inside them. its all yours.
            </p>
          </section>
        </Reveal>

        <Rule />

        {/* How it works */}
        <Reveal>
          <section id="how" style={section}>
            <h2 style={h2}>you do it once, it takes it from there.</h2>
            <div style={{ marginTop: 40 }}>
              {howSteps.map((s, i) => (
                <div key={s.title} style={stepRow} className="step-row">
                  <div style={stepNum}>{String(i + 1).padStart(2, "0")}</div>
                  <div style={{ maxWidth: 620 }}>
                    <div style={stepTitle}>{s.title}</div>
                    <div style={stepBody}>{s.body}</div>
                  </div>
                </div>
              ))}
            </div>
          </section>
        </Reveal>

        <Rule />

        {/* Accountability — make it stick */}
        <Reveal>
          <section id="stick" style={section}>
            <h2 style={h2}>block the feed. then make it actually stick.</h2>
            <p style={{ ...lede, maxWidth: 640, marginTop: 20 }}>
              willpower runs out. rinkler has a few ways to back you up when it
              does, and you pick as many as you want.
            </p>
            <div style={featGrid} className="feat-grid">
              {stickFeatures.map((f) => (
                <div key={f.title} style={featCard}>
                  <div style={colLabel}>{f.tag}</div>
                  <div style={featTitle}>{f.title}</div>
                  <div style={featBody}>{f.body}</div>
                </div>
              ))}
            </div>
            <p style={{ ...statement, color: signal.text, marginTop: 30 }}>
              and yeah, you can delete your account and everything tied to it
              right in the app, anytime.
            </p>
          </section>
        </Reveal>

        <Rule />

        {/* Privacy */}
        <Reveal>
          <section style={section}>
            <h2 style={{ ...h2, maxWidth: 760 }}>its just you and your phone.</h2>
            <p style={{ ...lede, maxWidth: 600, marginTop: 18 }}>
              it runs on your device. nothing gets saved, nothing gets sold. promise.
            </p>
            <Link href="/privacy" style={{ ...textBtn, display: "inline-block", marginTop: 24 }} className="text-btn">
              read the privacy policy →
            </Link>
          </section>
        </Reveal>

        <Rule />

        {/* Founder quote */}
        <Reveal>
          <section style={section}>
            <p style={{ ...quote }}>
              &ldquo;Id just be scrolling endlessly without even knowing whats going
              on and that would be the first thing i did going to sleep and waking
              up, i didnt even like or want to scroll but it just became a habit.
              Nobody was able to fix this issue, so i did.&rdquo;
            </p>
            <div style={{ ...colLabel, marginTop: 20 }}>the kid who made rinkler</div>
          </section>
        </Reveal>

        <Rule />

        {/* Final CTA */}
        <Reveal>
          <section style={{ ...section, paddingTop: "clamp(80px, 13vh, 160px)", paddingBottom: "clamp(80px, 13vh, 160px)" }}>
            <h2 style={{ ...h2, fontSize: "clamp(34px, 6vw, 64px)" }}>lets get your nights back.</h2>
            <p style={{ ...lede, marginTop: 18 }}>Rinkler drops August 10. grab early access and win back your life.</p>
            <div style={{ ...ctaRow, marginTop: 32 }}>
              <Link href={ctaHref} style={lightBtn} className="light-btn">{ctaLabel}</Link>
            </div>
          </section>
        </Reveal>
          </div>
        )}
      </main>

      {/* Footer */}
      {open && (
      <footer style={footer}>
        <span style={wordmark}>Rinkler</span>
        <div style={footerLinks} className="footer-links">
          <a href="https://niharm.me" target="_blank" rel="noopener noreferrer" style={navLink}>about me</a>
          <Link href="/privacy" style={navLink}>privacy</Link>
          <Link href="/terms" style={navLink}>terms</Link>
          <a href="mailto:nihar.manchikalapudi@gmail.com" style={navLink}>support</a>
          <Link href="/login" style={navLink}>log in</Link>
        </div>
        <span style={{ color: signal.textFaint, fontFamily: signal.mono, fontSize: 12 }}>© 2026</span>
      </footer>
      )}
    </div>
  );
}

// "endless scroll" that literally scrolls vertically. A long stack of copies
// keeps it going continuously — the loop point is ~2 minutes away and seamless
// (every copy is identical), so it never visibly breaks.
function EndlessScroll() {
  const phrases = Array.from({ length: 100 }, () => "endless scroll");
  return (
    <span style={vWrap}>
      <span style={vInner} className="vscroll">
        {phrases.map((p, i) => (
          <span key={i} style={vLine}>{p}</span>
        ))}
      </span>
    </span>
  );
}

function slowScrollTo(targetY: number, duration: number) {
  const startY = window.scrollY;
  const dist = targetY - startY;
  const start = performance.now();
  const ease = (t: number) => (t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2); // easeInOutCubic
  const step = (now: number) => {
    const p = Math.min(1, (now - start) / duration);
    // "instant" bypasses the CSS smooth-scroll so our easing isn't fought.
    window.scrollTo({ top: startY + dist * ease(p), behavior: "instant" as ScrollBehavior });
    if (p < 1) requestAnimationFrame(step);
  };
  requestAnimationFrame(step);
}

function Rule() {
  return <div style={{ height: 1, background: signal.border, maxWidth: 1080, margin: "0 auto", width: "100%" }} />;
}
function CompareRow({ text, good }: { text: string; good: boolean }) {
  return (
    <div style={compareRow}>
      <span style={{ ...compareMark, color: good ? signal.accent : signal.textFaint }}>{good ? "→" : "×"}</span>
      <span style={{ fontSize: 15.5, lineHeight: 1.5, color: good ? signal.text : signal.textDim }}>{text}</span>
    </div>
  );
}

const compareBad = [
  "blocks the whole app, DMs and all",
  "you unlock it for one sec and fall right back in",
  "guilt trips and lockouts you start to hate",
  "deleted by friday",
];
const compareGood = [
  "takes just the endless feed",
  "your DMs, search and posts still work",
  "no shame, ever, just whats real",
  "you actually keep it around",
];
const howSteps = [
  { title: "tell it about you", body: "a few quick questions and it builds your whole setup. you configure nothing." },
  { title: "start whenever", body: "one tap, or let it run on a schedule so its already working when you forget." },
  { title: "watch it add up", body: "real time back, a streak that grows, and zero lecture when you slip." },
];
const stickFeatures = [
  { tag: "friend control", title: "let a friend hold the keys", body: "hand someone a code and they set your limits from their own phone, for a window you pick. no second app to install, they just run it from rinkler.app/friend. you cant talk your way out of it." },
  { tag: "strict mode", title: "lock it and mean it", body: "commit for a set stretch with no backing out in the app. the only way out is deleting rinkler entirely, so you wont cave at 1am." },
  { tag: "automatic", title: "it reads the room", body: "hook up apple health and rinkler tightens your limits on its own when youre stressed or barely moved. it all stays on your phone and never gets sent anywhere." },
  { tag: "ads + trackers", title: "less junk, everywhere", body: "while protections on, rinkler quietly cuts ads and trackers across your apps too, not just the feeds." },
];

/* ---------- styles ---------- */
const page: CSSProperties = { background: signal.bg, color: signal.text, fontFamily: signal.sans, minHeight: "100vh" };
const main: CSSProperties = { maxWidth: 1080, margin: "0 auto", padding: "0 clamp(20px, 5vw, 40px)" };

const navBar: CSSProperties = {
  position: "fixed",
  top: 0,
  left: 0,
  right: 0,
  zIndex: 20,
  background: "rgba(8,8,10,0.72)",
  backdropFilter: "blur(12px)",
  WebkitBackdropFilter: "blur(12px)",
  borderBottom: `1px solid ${signal.border}`,
};
const navInner: CSSProperties = {
  maxWidth: 1080 + 80,
  margin: "0 auto",
  display: "flex",
  alignItems: "center",
  justifyContent: "space-between",
  padding: "14px clamp(20px, 5vw, 40px)",
};
const wordmark: CSSProperties = { display: "inline-flex", alignItems: "center", gap: 8, fontSize: 17, fontWeight: 600, color: signal.text, textDecoration: "none", letterSpacing: "-0.01em" };
const navRight: CSSProperties = { display: "flex", alignItems: "center", gap: 26 };
const navLink: CSSProperties = { color: signal.textDim, textDecoration: "none", fontSize: 14 };
const lightBtn: CSSProperties = { padding: "9px 18px", borderRadius: 8, background: signal.text, color: "#08080A", textDecoration: "none", fontSize: 14, fontWeight: 600 };
const lightBtnLg: CSSProperties = { ...lightBtn, padding: "13px 26px", fontSize: 15, borderRadius: 10 };

/* splash */
const splash: CSSProperties = {
  minHeight: "100vh",
  display: "flex",
  flexDirection: "column",
  alignItems: "center",
  justifyContent: "center",
  textAlign: "center",
  padding: "40px 0",
};
const splashLogo: CSSProperties = { display: "flex", alignItems: "center", justifyContent: "center", gap: 12, marginBottom: 18 };
const splashWord: CSSProperties = { fontSize: "clamp(40px, 9vw, 72px)", fontWeight: 600, letterSpacing: "-0.03em", color: signal.text };
const splashTag: CSSProperties = { fontSize: "clamp(15px, 2.1vw, 19px)", color: signal.textDim, maxWidth: 480, margin: "0 auto", lineHeight: 1.5 };
const countLabel: CSSProperties = { fontFamily: signal.mono, fontSize: 12, letterSpacing: "0.18em", textTransform: "uppercase", color: signal.textFaint, marginBottom: 18 };
const learnMore: CSSProperties = { display: "inline-block", marginTop: 44, color: signal.textDim, textDecoration: "none", fontSize: 14, fontFamily: signal.mono, letterSpacing: "0.04em", background: "none", border: "none", cursor: "pointer", padding: 0 };

/* vertical "endless scroll" ticker — lines touch (no gap) so the loop is
   truly continuous, with masked top/bottom edges. */
const vWrap: CSSProperties = {
  display: "inline-block",
  height: "1em",
  lineHeight: 1,
  overflow: "hidden",
  verticalAlign: "-0.12em",
  WebkitMaskImage: "linear-gradient(to bottom, transparent, #000 18%, #000 82%, transparent)",
  maskImage: "linear-gradient(to bottom, transparent, #000 18%, #000 82%, transparent)",
};
const vInner: CSSProperties = { display: "block", willChange: "transform" };
const vLine: CSSProperties = { display: "block", height: "1em", lineHeight: 1, whiteSpace: "nowrap", color: signal.text, fontWeight: 600 };

const section: CSSProperties = { padding: "clamp(64px, 10vh, 120px) 0" };
const h1: CSSProperties = { fontSize: "clamp(42px, 8vw, 88px)", lineHeight: 1.0, fontWeight: 600, letterSpacing: "-0.04em", margin: 0, maxWidth: 980 };
const h2: CSSProperties = { fontSize: "clamp(28px, 4.6vw, 48px)", lineHeight: 1.04, fontWeight: 600, letterSpacing: "-0.03em", margin: 0 };
const lede: CSSProperties = { fontSize: "clamp(16px, 1.8vw, 19px)", lineHeight: 1.6, color: signal.textDim, maxWidth: 540, margin: 0 };
const statement: CSSProperties = { fontSize: "clamp(19px, 2.6vw, 26px)", lineHeight: 1.45, color: signal.textDim, maxWidth: 820, margin: "26px 0 0", letterSpacing: "-0.01em" };

const ctaRow: CSSProperties = { display: "flex", flexWrap: "wrap", alignItems: "center", gap: 22, marginTop: 36 };
const textBtn: CSSProperties = { color: signal.text, textDecoration: "none", fontSize: 15, fontWeight: 500 };

const compareGrid: CSSProperties = { display: "grid", gridTemplateColumns: "1fr 1fr", gap: 0, marginTop: 44 };
const colLabel: CSSProperties = { fontFamily: signal.mono, fontSize: 12, letterSpacing: "0.12em", textTransform: "uppercase", color: signal.textFaint, marginBottom: 20 };
const compareRow: CSSProperties = { display: "flex", gap: 14, alignItems: "flex-start", padding: "11px 0", borderTop: `1px solid ${signal.border}` };
const compareMark: CSSProperties = { fontFamily: signal.mono, fontSize: 14, lineHeight: 1.55, flexShrink: 0, width: 14 };

const featGrid: CSSProperties = { display: "grid", gridTemplateColumns: "1fr 1fr", gap: 1, marginTop: 44, background: signal.border, border: `1px solid ${signal.border}`, borderRadius: 14, overflow: "hidden" };
const featCard: CSSProperties = { background: signal.bg, padding: "28px 26px" };
const featTitle: CSSProperties = { fontSize: 20, fontWeight: 600, color: signal.text, letterSpacing: "-0.01em", marginTop: 6 };
const featBody: CSSProperties = { fontSize: 15, lineHeight: 1.6, color: signal.textDim, marginTop: 10 };

const stepRow: CSSProperties = { display: "flex", gap: 32, padding: "26px 0", borderTop: `1px solid ${signal.border}` };
const stepNum: CSSProperties = { fontFamily: signal.mono, fontSize: 14, color: signal.textFaint, paddingTop: 4, width: 36, flexShrink: 0 };
const stepTitle: CSSProperties = { fontSize: 19, fontWeight: 600, color: signal.text, letterSpacing: "-0.01em" };
const stepBody: CSSProperties = { fontSize: 15, lineHeight: 1.6, color: signal.textDim, marginTop: 8 };


const quote: CSSProperties = { fontSize: "clamp(20px, 2.8vw, 28px)", lineHeight: 1.45, color: signal.text, maxWidth: 820, fontWeight: 400, letterSpacing: "-0.01em", margin: "20px 0 0" };

const footer: CSSProperties = {
  maxWidth: 1080,
  margin: "0 auto",
  display: "flex",
  alignItems: "center",
  justifyContent: "space-between",
  flexWrap: "wrap",
  gap: 16,
  padding: "28px clamp(20px, 5vw, 40px)",
  borderTop: `1px solid ${signal.border}`,
};
const footerLinks: CSSProperties = { display: "flex", flexWrap: "wrap", gap: "12px 24px" };

const css = `
  html { scroll-behavior: smooth; }
  .nav-in { animation: navDown 0.6s cubic-bezier(0.22,1,0.36,1) both; }
  @keyframes navDown { from { transform: translateY(-100%); opacity: 0; } to { transform: none; opacity: 1; } }
  @media (prefers-reduced-motion: reduce) { .nav-in { animation: none; } }
  .vscroll { animation: vscroll 130s linear infinite; }
  @keyframes vscroll { from { transform: translateY(0); } to { transform: translateY(-50%); } }
  @media (prefers-reduced-motion: reduce) { .vscroll { animation: none; } }
  .light-btn { transition: opacity 0.15s ease; }
  .light-btn:hover { opacity: 0.85; }
  .text-btn:hover { color: ${signal.textDim}; }
  .nav-links a:hover, .footer-links a:hover { color: ${signal.text}; }
  @media (max-width: 720px) {
    .compare { grid-template-columns: 1fr !important; }
    .feat-grid { grid-template-columns: 1fr !important; }
    .compare-right { padding-left: 0 !important; border-left: 0 !important; border-top: 1px solid ${signal.border}; padding-top: 28px; margin-top: 8px; }
    .nav-links a:not(:last-child) { display: none; }
    .br-hide { display: none; }
  }
`;
