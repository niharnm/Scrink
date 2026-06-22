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
    // Let the content fade in first, then glide down slowly — calmer than a snap.
    setTimeout(() => {
      const el = document.getElementById("more");
      if (!el) return;
      if (reduce) {
        el.scrollIntoView();
        return;
      }
      slowScrollTo(el.getBoundingClientRect().top + window.scrollY, 1200);
    }, 260);
  };

  return (
    <div style={page}>
      <style dangerouslySetInnerHTML={{ __html: css }} />

      {/* Nav (revealed with the rest of the page) */}
      {open && (
        <header style={nav}>
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
          <section id="more" style={{ ...section, paddingTop: "clamp(48px, 8vh, 90px)", paddingBottom: "clamp(72px, 12vh, 150px)" }}>
            <h1 style={h1}>
              your phone isnt<br className="br-hide" /> the problem.
              <br />
              <span style={{ color: signal.textFaint }}>the feed is.</span>
            </h1>
            <p style={{ ...lede, marginTop: 28 }}>
              rinkler cuts the endless reels and tiktoks that eat your night, and
              leaves the stuff you actually opened the app for. dms, search,
              messages, all still there.
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

        {/* The real fight */}
        <Reveal>
          <section style={section}>
            <h2 style={h2}>youre not weak. its rigged.</h2>
            <p style={statement}>
              you open instagram to answer one text. forty minutes later youre
              watching some guy fix a rusted wrench and you dont even know how you
              got there. thats not you being lazy. the feed is built by hundreds of
              engineers testing every pixel to keep you swiping. you were never
              gonna beat that with willpower.
            </p>
            <p style={{ ...statement, color: signal.text, marginTop: 20 }}>
              rinkler evens it out, at the one spot the feed cant talk you out of.
            </p>
          </section>
        </Reveal>

        <Rule />

        {/* Scalpel */}
        <Reveal>
          <section id="difference" style={section}>
            <h2 style={h2}>it cuts the feed, not the whole app.</h2>
            <p style={{ ...lede, maxWidth: 680, marginTop: 20 }}>
              most blockers are all or nothing. you block instagram, then unblock
              it to send one dm, and youre right back in the feed. thats why people
              delete them in a week. rinkler only cuts the short video feed and
              leaves everything else working. theres nothing to ragequit.
            </p>
            <div style={compareGrid} className="compare">
              <div style={{ paddingRight: 32 }}>
                <div style={colLabel}>blanket blockers</div>
                {compareBad.map((t) => <CompareRow key={t} text={t} good={false} />)}
              </div>
              <div style={{ paddingLeft: 32, borderLeft: `1px solid ${signal.border}` }} className="compare-right">
                <div style={{ ...colLabel, color: signal.text }}>rinkler</div>
                {compareGood.map((t) => <CompareRow key={t} text={t} good />)}
              </div>
            </div>
          </section>
        </Reveal>

        <Rule />

        {/* How it works */}
        <Reveal>
          <section id="how" style={section}>
            <h2 style={h2}>set it up once, it handles the rest.</h2>
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

        {/* Honest */}
        <Reveal>
          <section style={section}>
            <h2 style={h2}>how it actually works.</h2>
            <div style={featGrid} className="feat-grid">
              {features.map((f) => (
                <div key={f.title}>
                  <div style={featTitle}>{f.title}</div>
                  <div style={featBody}>{f.body}</div>
                </div>
              ))}
            </div>
          </section>
        </Reveal>

        <Rule />

        {/* Privacy */}
        <Reveal>
          <section style={section}>
            <h2 style={{ ...h2, maxWidth: 760 }}>it runs on your phone and never reads your stuff.</h2>
            <p style={{ ...lede, maxWidth: 640, marginTop: 20 }}>
              the filter runs locally. your traffic never goes through a server. it
              only sees where a connection is headed and how big it is, never whats
              inside. no messages read, nothing stored, nothing sold.
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
              up, i dint even like or want to scroll but it just became a habit.
              Nobody was able to fix this issue, so i did.&rdquo;
            </p>
            <div style={{ ...colLabel, marginTop: 20 }}>the kid who made rinkler</div>
          </section>
        </Reveal>

        <Rule />

        {/* Final CTA */}
        <Reveal>
          <section style={{ ...section, paddingTop: "clamp(80px, 13vh, 160px)", paddingBottom: "clamp(80px, 13vh, 160px)" }}>
            <h2 style={{ ...h2, fontSize: "clamp(34px, 6vw, 64px)" }}>get your time back.</h2>
            <p style={{ ...lede, marginTop: 18 }}>launching july 10. get early access and win your first ten quiet minutes.</p>
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
        <div style={footerLinks} className="nav-links">
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
  "blocks the whole app, dms and all",
  "you unlock it for a sec and fall back in",
  "guilt trips and lockouts you hate",
  "deleted within a week",
];
const compareGood = [
  "only cuts the short video feed",
  "dms, search and posts still work",
  "no shame, just real numbers",
  "sticks, theres nothing to ragequit",
];
const howSteps = [
  { title: "build your setup", body: "answer a few questions when you first open the app and rinkler makes the rules for you. homework mode, night lock, a clean morning. you dont touch a single setting." },
  { title: "start a session", body: "one tap. pick how strict you want it, from chill to a locked deep session you cant quit early. it runs on a schedule too, so it kicks in even when the app is closed." },
  { title: "watch it stack up", body: "real focused time and blocked feeds add up. build a streak and see exactly how much scroll you cut. its all real, nothing made up." },
];
const features = [
  { title: "stays on your phone", body: "everything runs on your device. your traffic never hits our servers and we never look inside it." },
  { title: "cuts the feed, not the app", body: "it goes after the endless short video feed, not your whole phone, so the useful parts of every app still work." },
  { title: "runs on a schedule", body: "your windows kick in on time even with the app closed, so its already on right when youd usually slip." },
  { title: "real numbers", body: "every stat is measured on your phone, not guessed. real time saved, real feeds blocked, no lecture when you slip." },
];

/* ---------- styles ---------- */
const page: CSSProperties = { background: signal.bg, color: signal.text, fontFamily: signal.sans, minHeight: "100vh" };
const main: CSSProperties = { maxWidth: 1080, margin: "0 auto", padding: "0 clamp(20px, 5vw, 40px)" };

const nav: CSSProperties = {
  position: "sticky",
  top: 0,
  zIndex: 10,
  display: "flex",
  alignItems: "center",
  justifyContent: "space-between",
  padding: "16px clamp(20px, 5vw, 40px)",
  maxWidth: 1080 + 80,
  margin: "0 auto",
  background: "rgba(8,8,10,0.8)",
  backdropFilter: "blur(10px)",
  borderBottom: `1px solid ${signal.border}`,
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

const stepRow: CSSProperties = { display: "flex", gap: 32, padding: "26px 0", borderTop: `1px solid ${signal.border}` };
const stepNum: CSSProperties = { fontFamily: signal.mono, fontSize: 14, color: signal.textFaint, paddingTop: 4, width: 36, flexShrink: 0 };
const stepTitle: CSSProperties = { fontSize: 19, fontWeight: 600, color: signal.text, letterSpacing: "-0.01em" };
const stepBody: CSSProperties = { fontSize: 15, lineHeight: 1.6, color: signal.textDim, marginTop: 8 };

const featGrid: CSSProperties = { display: "grid", gridTemplateColumns: "1fr 1fr", gap: "40px 56px", marginTop: 44 };
const featTitle: CSSProperties = { fontSize: 17, fontWeight: 600, color: signal.text, marginBottom: 8, letterSpacing: "-0.01em" };
const featBody: CSSProperties = { fontSize: 14.5, lineHeight: 1.6, color: signal.textDim };

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
const footerLinks: CSSProperties = { display: "flex", gap: 24 };

const css = `
  html { scroll-behavior: smooth; }
  .reveal-content { animation: contentIn 0.9s cubic-bezier(0.22,1,0.36,1) both; }
  @keyframes contentIn { from { opacity: 0; transform: translateY(12px); } to { opacity: 1; transform: none; } }
  @media (prefers-reduced-motion: reduce) { .reveal-content { animation: none; } }
  .vscroll { animation: vscroll 130s linear infinite; }
  @keyframes vscroll { from { transform: translateY(0); } to { transform: translateY(-50%); } }
  @media (prefers-reduced-motion: reduce) { .vscroll { animation: none; } }
  .light-btn { transition: opacity 0.15s ease; }
  .light-btn:hover { opacity: 0.85; }
  .text-btn:hover { color: ${signal.textDim}; }
  .nav-links a:hover { color: ${signal.text}; }
  @media (max-width: 720px) {
    .compare { grid-template-columns: 1fr !important; }
    .compare-right { padding-left: 0 !important; border-left: 0 !important; border-top: 1px solid ${signal.border}; padding-top: 28px; margin-top: 8px; }
    .feat-grid { grid-template-columns: 1fr !important; }
    .nav-links a:not(:last-child) { display: none; }
    .br-hide { display: none; }
  }
`;
